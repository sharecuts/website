//
//  Shortcut.swift
//  App
//
//  Created by Guilherme Rambo on 07/07/18.
//

import Foundation
import Vapor
import FluentPostgreSQL

final class Shortcut: Codable {

    var id: UUID?
    var createdAt: Date
    var updatedAt: Date
    var userID: User.ID
    var tagID: Tag.ID

    var title: String
    var summary: String

    var filePath: String
    var fileID: String
    var actionCount: Int
    var actionIdentifiers: [String]
    var votes: Int

    var user: Parent<Shortcut, User> {
        return parent(\.userID)
    }
    
    var tag: Parent<Shortcut, Tag> {
        return parent(\.tagID)
    }

    init(userID: User.ID,
         tagID: Tag.ID,
         title: String,
         summary: String,
         filePath: String,
         fileID: String,
         actionCount: Int,
         actionIdentifiers: [String],
         votes: Int = 0)
    {
        self.createdAt = Date()
        self.updatedAt = Date()
        self.userID = userID
        self.tagID = tagID
        self.title = title
        self.summary = summary
        self.filePath = filePath
        self.fileID = fileID
        self.actionCount = actionCount
        self.actionIdentifiers = actionIdentifiers
        self.votes = votes
    }
}

extension Shortcut: PostgreSQLUUIDModel { }
extension Shortcut: Content { }
extension Shortcut: Migration { }
extension Shortcut: Parameter { }

extension Shortcut: OwnedByUser { }

struct AddIndigoFieldsToShortcut: PostgreSQLMigration {
    
    static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return Database.update(Shortcut.self, on: conn) { builder in
            builder.field(for: \.votes, type: .int, .default(.literal(0)))
        }
    }
    
    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return Database.update(Shortcut.self, on: conn) { builder in
            builder.deleteField(for: \.votes)
        }
    }
    
}

struct AddTagToShortcut: PostgreSQLMigration {
    
    static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return Database.update(Shortcut.self, on: conn) { builder in
            builder.field(for: \.tagID, type: .uuid, .default(.literal("2F46B7B4-A9FC-45F6-BA23-717CEF56CE74")))
        }
    }
    
    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return Database.update(Shortcut.self, on: conn) { builder in
            builder.deleteField(for: \.tagID)
        }
    }
    
}
