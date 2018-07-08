//
//  User.swift
//  App
//
//  Created by Guilherme Rambo on 07/07/18.
//

import Foundation
import Vapor
import FluentPostgreSQL

final class User: Codable {
    var id: UUID?
    var name: String
    var username: String
    var url: URL
    var apiKey: String?

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
}

extension User: PostgreSQLUUIDModel { }
extension User: Content { }
extension User: Migration { }
extension User: Parameter { }
