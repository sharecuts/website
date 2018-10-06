import FluentPostgreSQL
import Vapor
import DotEnv
import Leaf
import Authentication

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    let env = DotEnv(withFile: ".env")

    let key = env.get("MASTER_KEY") ?? "a3RXcXguZWJXI1FOVkx5ODJ2YjdhYzhLbVtvYjcmPkQyKk1LTjQrcUtkS0AqNkZXbXg4eWtjd256aSpFeUxnMg"

    B2Client.shared.config = B2Config(env: env)

    let downloadsBase = env.get("B2_BUCKET_BASE_URL") ?? "https://f001.backblazeb2.com/file/sharecuts/"

    /// Register providers first
    try services.register(FluentPostgreSQLProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router, masterKey: key, downloadsBaseURL: URL(string: downloadsBase)!)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    middlewares.use(SessionsMiddleware.self)
    services.register(middlewares)
    
    config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)

    try services.register(LeafProvider())
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)
    
    try services.register(AuthenticationProvider())

    let databaseHost = env.get("DB_HOST") ?? "localhost"
    let databasePort = env.getAsInt("DB_PORT") ?? 5432
    let databaseUser = env.get("DB_USER") ?? "inside"
    let databaseName = env.get("DB_NAME") ?? "inside"
    let databasePassword = env.get("DB_PWD")

    let psqlConfig = PostgreSQLDatabaseConfig(
        hostname: databaseHost,
        port: databasePort,
        username: databaseUser,
        database: databaseName,
        password: databasePassword
    )

    services.register(psqlConfig)

    /// Configure migrations
    var migrations = MigrationConfig()

    migrations.add(model: Shortcut.self, database: .psql)
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: Token.self, database: .psql)

    migrations.add(migration: AddIndigoFieldsToUser.self, database: .psql)
    migrations.add(migration: MigrateExistingUsersToIndigo.self, database: .psql)

    services.register(migrations)

    services.register(CloudFlareClient.self) { (container: Container) -> CloudFlareClient in
        let logger = try container.make(Logger.self)
        return CloudFlareClient(env: env, logger: logger)
    }
    
    services.register(VotingClient.self) { (container: Container) -> VotingClient in
        return try VotingClient(container: container)
    }
}
