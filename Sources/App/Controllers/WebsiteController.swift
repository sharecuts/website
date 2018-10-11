//
//  WebsiteController.swift
//  App
//
//  Created by Guilherme Rambo on 07/07/18.
//

import Foundation

import Foundation
import Vapor
import FluentPostgreSQL
import Leaf
import Authentication

final class WebsiteController: RouteCollection {

    let downloadsBaseURL: URL

    init(downloadsBaseURL: URL) {
        self.downloadsBaseURL = downloadsBaseURL
    }

    func boot(router: Router) throws {
        router.get("/feed.xml", use: feedRSS)
        router.get("/feed.json", use: feedJSON)
        
        let authSessionRoutes = router.grouped(User.authSessionsMiddleware())
        
        authSessionRoutes.get(use: index)
        authSessionRoutes.get("download", String.parameter, use: download)
        authSessionRoutes.get("about", use: about)
        authSessionRoutes.get("search", use: search)
        authSessionRoutes.get("pwned", use: pwned)
        
        let redirect = RedirectMiddleware<User>(path: "/users/login")

        let userRoutes = authSessionRoutes.grouped("users")
        
        userRoutes.get("signup", use: signupForm)
        userRoutes.post(SignupData.self, at: "signup", use: signup)
        userRoutes.get("migrateToIndigo", use: migrateUserToIndigo)
        userRoutes.post("migrateToIndigo", use: performUserMigrationToIndigo)

        userRoutes.get("login", use: loginForm)
        userRoutes.post(LoginRequest.self, at: "login", use: performLogin)
        userRoutes.get(String.parameter, use: userPage)
        
        let protectedUserRoutes = userRoutes.grouped(redirect)
        
        protectedUserRoutes.post("logout", use: logout)
        
        let protectedRoutes = authSessionRoutes.grouped(redirect)
     
        protectedRoutes.get("upload", use: upload)
        
        let tagRoutes = authSessionRoutes.grouped("tags")
        
        tagRoutes.get(String.parameter, use: tag)
    }
    
    private func navigationContext(in req: Request, with tag: Tag? = nil) -> Future<NavigationContext> {
        let query = Tag.query(on: req).sort(\.name, .ascending).all()
        
        return query.map(to: NavigationContext.self) { tags in
            return NavigationContext(tags: tags, activeTag: tag)
        }
    }
    
    private func homeContext(with req: Request, count: Int = 50) -> Future<HomeContext> {
        let query = Shortcut.query(on: req).range(0...count).sort(\.createdAt, .descending).all()

        return navigationContext(in: req).flatMap(to: HomeContext.self) { navContext in
            return query.flatMap(to: HomeContext.self) { shortcuts in
                let userFutures = shortcuts.map({ $0.user.query(on: req).first() })
                
                return userFutures.map(to: HomeContext.self, on: req) { users in
                    let unwrappedUsers = users.compactMap({ $0 })
                    let cards = shortcuts.compactMap({ try? ShortcutCard($0, users: unwrappedUsers, req: req) })
                    
                    return HomeContext(navigation: navContext, cards: cards)
                }
            }
        }
    }

    func index(_ req: Request) throws -> Future<View> {
        return homeContext(with: req).flatMap(to: View.self) { context in
            return try req.view().render("index", context)
        }
    }

    private static let forceWorkflowExtension = false

    func download(_ req: Request) throws -> Future<Response> {
        let identifier = req.http.url.deletingPathExtension().lastPathComponent

        guard let id = UUID(uuidString: identifier) else {
            throw Abort(.badRequest)
        }

        let shortcutQuery = Shortcut.find(id, on: req)

        return shortcutQuery.flatMap(to: Response.self) { shortcut in
            guard let shortcut = shortcut else {
                throw Abort(.notFound)
            }

            let url = self.downloadsBaseURL.appendingPathComponent(shortcut.filePath)

            let download = B2Client.shared.fetchFileData(from: url, on: req)
            
            shortcut.downloads += 1
            
            let downloadFuture = download.flatMap(to: Response.self) { data in
                guard let data = data else {
                    throw Abort(.notFound)
                }
                
                let ext = WebsiteController.forceWorkflowExtension ? "wflow" : "shortcut"
                
                let disposition = "attachment; filename=\"\(shortcut.title).\(ext)\""
                
                let status = HTTPResponseStatus(statusCode: 200)
                let headers = HTTPHeaders([
                    ("Content-Type","application/octet-stream"),
                    ("Content-Length", String(data.count)),
                    ("Content-Disposition", disposition)
                    ])
                
                return Future.map(on: req) { req.response(http: HTTPResponse(status: status, headers: headers, body: data)) }
            }
            
            return map(to: Response.self, shortcut.save(on: req), downloadFuture) { _, download in
                return download
            }
        }
    }

    func upload(_ req: Request) throws -> Future<View> {
        let user = try req.requireAuthenticated(User.self)
        
        let tags = Tag.query(on: req).sort(\.name).all()
        
        let error = req.query[String.self, at: "error"]

        return tags.flatMap(to: View.self) { tags in
            let context = UploadContext(user, tags: tags, error: error)
            
            return try req.view().render("upload", context)
        }
    }

    func about(_ req: Request) throws -> Future<View> {
        return try req.view().render("about")
    }
    
    // MARK: - Search

    func search(_ req: Request) throws -> Future<View> {
        let searchTerm = req.query[String.self, at: "query"]
        
        guard let term = searchTerm else {
            return try req.view().render("search")
        }
        
        guard term.count > 3 else {
            return try req.view().render("search", ["error": true])
        }
        
        let query = Shortcut.query(on: req)
            .filter(\.title, PostgreSQLBinaryOperator.ilike, "%\(term)%")
            .range(0...100)
            .sort(\.createdAt, .descending)
            .all()
        
        return query.flatMap(to: View.self) { shortcuts in
            let userFutures = shortcuts.map({ $0.user.query(on: req).first() })
            
            return userFutures.flatMap(to: View.self, on: req) { users in
                let unwrappedUsers = users.compactMap({ $0 })
                let cards = shortcuts.compactMap({ try? ShortcutCard($0, users: unwrappedUsers, req: req) })
                
                return try req.view().render("search", ["cards": cards])
            }
        }
    }
    
    // MARK: - User routes
    
    func userPage(_ req: Request) throws -> Future<View> {
        let usernameParam = try req.parameters.next(String.self)
        
        let userQuery = User.query(on: req).filter(\.username, .equal, usernameParam).first()
        
        return userQuery.flatMap { user in
            guard let user = user else {
                throw Abort(.notFound)
            }
            
            let shortcuts = try user.shortcuts.query(on: req).all()
            
            return self.navigationContext(in: req).flatMap(to: View.self) { navContext in
                return shortcuts.flatMap(to: View.self) { shortcuts in
                    let cards = shortcuts.compactMap({ try? ShortcutCard($0, users: [user], req: req) })
                    
                    let context = UserDetailsContext(navigation: navContext, user: user, cards: cards)

                    return try req.view().render("users/details", context)
                }
            }
        }
    }
    
    func loginForm(_ req: Request) throws -> Future<View> {
        let hasError = req.query[Bool.self, at: "error"] != nil
        
        let context = LoginContext(error: hasError)
        
        return try req.view().render("users/login", context)
    }
    
    func performLogin(_ req: Request, login: LoginRequest) throws -> Future<Response> {
        let auth = User.authenticate(
            username: login.username,
            password: login.password,
            using: BCryptDigest(),
            on: req
        )
        
        return auth.map(to: Response.self) { user in
            guard let user = user else {
                return req.redirect(to: "/users/login?error=1")
            }
            
            try req.authenticateSession(user)
            
            return req.redirect(to: "/upload")
        }
    }
    
    func logout(_ req: Request) throws -> Response {
        try req.unauthenticateSession(User.self)
        
        return req.redirect(to: "/")
    }
    
    // MARK: - Tag routes
    
    func tag(_ req: Request) throws -> Future<View> {
        let tagSlug = try req.parameters.next(String.self)
        
        let tagQuery = Tag.query(on: req).filter(\.slug, .equal, tagSlug).first()
        
        return tagQuery.flatMap { tag in
            guard let tag = tag else {
                throw Abort(.notFound)
            }
            
            let shortcuts = try tag.shortcuts.query(on: req).all()
            
            return self.navigationContext(in: req, with: tag).flatMap(to: View.self) { navContext in
                return shortcuts.flatMap(to: View.self) { shortcuts in
                    let userFutures = shortcuts.map({ $0.user.query(on: req).first() })
                    
                    return userFutures.flatMap(to: View.self, on: req) { users in
                        let unwrappedUsers = users.compactMap({ $0 })
                        let cards = shortcuts.compactMap({ try? ShortcutCard($0, users: unwrappedUsers, req: req) })
                        
                        let context = TagDetailsContext(navigation: navContext, tag: tag, cards: cards)
                        
                        return try req.view().render("tag", context)
                    }
                }
            }
        }
    }
    
    // MARK: - User migration
    
    func migrateUserToIndigo(_ req: Request) throws -> Future<View> {
        let specificError = req.query[String.self, at: "error"]

        guard let key = req.query[String.self, at: "apiKey"] else {
            let ctx = IndigoMigrationContext(error: "You need to provide your API key")
            return try req.view().render("users/indigo", ctx)
        }
        
        guard let username = req.query[String.self, at: "username"] else {
            let ctx = IndigoMigrationContext(error: "You need to provide your username. It's the same one you use on Twitter.")
            return try req.view().render("users/indigo", ctx)
        }
        
        let userQuery = User.query(on: req).filter(\.username, .equal, username).first()
        
        return userQuery.flatMap(to: View.self) { user in
            guard let user = user, let userKey = user.apiKey else {
                let ctx = IndigoMigrationContext(error: "User not found.")
                return try req.view().render("users/indigo", ctx)
            }
            
            guard try BCrypt.verify(key, created: userKey) else {
                let ctx = IndigoMigrationContext(error: "Invalid API key.")
                return try req.view().render("users/indigo", ctx)
            }
            
            let ctx = IndigoMigrationContext(user: user, apiKey: key, error: specificError)

            return try req.view().render("users/indigo", ctx)
        }
    }
    
    func performUserMigrationToIndigo(_ req: Request) throws -> Future<Response> {
        let reqFuture = try req.content.decode(IndigoMigrationRequest.self)
        
        return reqFuture.flatMap(to: Response.self) { migrationRequest in
            let redirect = "/users/migrateToIndigo?username=\(migrationRequest.username)&apiKey=\(migrationRequest.apiKey)"
            
            func makeRedir(with error: String) -> EventLoopFuture<Response> {
                return Future.map(on: req) {
                    let encodedError = error.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Fatal"
                    return req.redirect(to: redirect + "&error=\(encodedError)")
                }
            }
            
            let userQuery = User.query(on: req).filter(\.username, .equal, migrationRequest.username).first()
            
            return userQuery.flatMap(to: Response.self) { user in
                guard let user = user, let userKey = user.apiKey else {
                    return makeRedir(with: "User not found")
                }
                
                guard migrationRequest.password.count >= 8 else {
                    return makeRedir(with: "Your password must be at least 8 characters long")
                }
                
                guard migrationRequest.password == migrationRequest.password2 else {
                    return makeRedir(with: "Password confirmation must match the password")
                }
                
                guard try BCrypt.verify(migrationRequest.apiKey, created: userKey) else {
                    return makeRedir(with: "Invalid API key")
                }
                
                let verifier = try req.make(PwnageVerifier.self)
                
                let pwnageVerification = verifier.verify(password: migrationRequest.password)
                
                return pwnageVerification.flatMap(to: Response.self) { pwnageResult in
                    if case .pwned(let count) = pwnageResult {
                        let learnMoreLink = "<a href=\"/pwned\" target=\"_blank\">What's this?</a>"
                        return makeRedir(with: "Sorry, this password has been found on \(count) security incidents, you need to choose a secure one. \(learnMoreLink)")
                    }
                    
                    user.password = try BCrypt.hash(migrationRequest.password)
                    
                    return user.save(on: req).map(to: Response.self) { _ in
                        return req.redirect(to: "/")
                    }
                }
            }
        }
    }
    
    func pwned(_ req: Request) throws -> Future<View> {
        return try req.view().render("pwned");
    }
    
    func signupForm(_ req: Request) throws -> Future<View> {
        let view = "users/signup"
        
        func inviteError(_ message: String = "You need an invite to register.") throws -> Future<View> {
            let ctx = RegistrationContext(error: message, partialUser: nil)
            return try req.view().render(view, ctx)
        }
        
        guard let invite = req.query[String.self, at: "invite"] else {
            return try inviteError()
        }
        
        let inviteQuery = Invite.query(on: req).filter(\.code, .equal, invite).first()
        
        return inviteQuery.flatMap(to: View.self) { invite in
            guard let invite = invite else {
                return try inviteError()
            }
            guard invite.usedAt == nil else {
                return try inviteError("This invite has already been used.")
            }
            
            let context = RegistrationContext(error: nil, partialUser: nil, invite: invite)

            return try req.view().render(view, context);
        }
    }
    
    func signup(_ req: Request, data: SignupData) throws -> Future<Response> {
        let password = try BCrypt.hash(data.password)
        
        let inviteQuery = Invite.query(on: req).filter(\.code, .equal, data.invite).first()
        
        return inviteQuery.flatMap(to: Response.self) { invite in
            guard let invite = invite else {
                return Future.map(on: req) { req.redirect(to: "/users/signup?error=1") }
            }
            
            invite.usedAt = Date()
            
            return invite.save(on: req).flatMap { _ in
                let user = User(
                    id: nil,
                    name: data.name,
                    username: data.username,
                    password: password,
                    url: URL(string: data.url) ?? URL(string: "https://sharecuts.app")!,
                    apiKey: nil
                )
                
                return user.save(on: req).map(to: Response.self) { user in
                    try req.authenticateSession(user)
                    
                    return req.redirect(to: "/")
                }
            }
        }
    }
    
    // MARK: - Feed
    
    func feedRSS(_ req: Request) throws -> Future<Response> {
        return homeContext(with: req, count: 100).flatMap(to: Response.self) { context in
            let view = try req.view().render("feed.xml", context)
            
            return view.map(to: Response.self) { view in
                return req.response(view.data, as: .xml)
            }
        }
    }
    
    func feedJSON(_ req: Request) throws -> Future<JSONFeed> {
        return homeContext(with: req, count: 100).map(to: JSONFeed.self) { context in
            return try JSONFeed(cards: context.cards)
        }
    }

}
