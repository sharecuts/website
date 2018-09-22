//
//  User.swift
//  App
//
//  Created by Guilherme Rambo on 07/07/18.
//

import Foundation
import Vapor
import FluentPostgreSQL
import Crypto

final class User: Codable {
    var id: UUID?
    var name: String
    var username: String
    var password: String = ""
    var rawLevel: Int = Level.defaultForNewUsers.rawValue
    var url: URL
    var apiKey: String?

    var level: Level {
        get {
            return Level(rawValue: rawLevel) ?? .normal
        }
        set {
            rawLevel = newValue.rawValue
        }
    }

    enum Level: Int, Codable, CaseIterable {
        case administrator = 100
        case moderator = 50
        case verifiedPublisher = 30
        case publisher = 20
        case normal = 0
        case suspended = -50
        case banned = -100

        static var defaultForNewUsers: Level {
            return .normal
        }
    }

    init(id: UUID?,
         name: String,
         username: String,
         password: String,
         url: URL,
         apiKey: String?,
         level: Level = .normal)
    {
        self.id = id
        self.name = name
        self.username = username
        self.password = password
        self.url = url
        self.apiKey = apiKey
        self.rawLevel = level.rawValue
    }

    var shortcuts: Children<User, Shortcut> {
        return children(\.userID)
    }

    var firstName: String? {
        guard #available(macOS 10.12, *) else { return nil }

        guard let components = PersonNameComponentsFormatter().personNameComponents(from: name) else {
            return nil
        }

        return components.givenName
    }

    struct Public: Codable {
        let id: UUID?
        let name: String
        let username: String
        let url: URL
    }

    struct CreateRequest: Codable {
        let id: UUID?
        let name: String
        let username: String
        let password: String
        let url: URL
        let rawLevel: Int?
        let apiKey: String
    }

}

// MARK: - Extensions

extension User: PostgreSQLUUIDModel { }
extension User: Content { }
extension User: Parameter { }

extension User.Public: Content { }
extension User.CreateRequest: Content { }

extension User {

    var publicView: Public {
        return Public(id: id, name: name, username: username, url: url)
    }

}

// MARK: - Migrations

extension User: Migration {

    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
        }
    }

}

/// Adds password and rawLevel fields to the User table
struct AddIndigoFieldsToUser: PostgreSQLMigration {

    static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return Database.update(User.self, on: conn) { builder in
            builder.field(for: \.password, type: .text, .default(.literal("")))

            let defaultLevelValue = "\(User.Level.defaultForNewUsers.rawValue)"

            builder.field(for: \.rawLevel, type: .int4, .default(.literal(.numeric(defaultLevelValue))))

            builder.unique(on: \.username)
        }
    }

    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return Database.update(User.self, on: conn) { builder in
            builder.deleteField(for: \.password)
            builder.deleteField(for: \.rawLevel)
            builder.deleteUnique(from: \.username)
        }
    }

}

/// Hashes existing api keys in the User table
struct MigrateExistingUsersToIndigo: PostgreSQLMigration {

    static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        let updateUsers = User.query(on: conn).all().flatMap { users -> EventLoopFuture<[User]> in
            users.forEach { user in
                guard let key = user.apiKey else { return }

                let keyHash = try! BCrypt.hash(key)
                user.apiKey = keyHash
            }

            return users.map({ $0.save(on: conn) }).flatten(on: conn)
        }

        return updateUsers.map(to: Void.self, { users -> Void in
            return
        })
    }

    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return Future.map(on: conn, { })
    }

}
