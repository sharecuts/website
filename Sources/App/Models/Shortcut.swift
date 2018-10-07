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
    var downloads: Int
    
    var color: Int
    
    var fileHash: String

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
         fileHash: String,
         votes: Int = 0,
         downloads: Int = 0,
         color: Int = 0)
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
        self.fileHash = fileHash
        self.votes = votes
        self.downloads = downloads
        self.color = color
    }
}

extension Shortcut: PostgreSQLUUIDModel { }
extension Shortcut: Content { }
extension Shortcut: Migration { }
extension Shortcut: Parameter { }

extension Shortcut: OwnedByUser { }

extension Shortcut {
    var effectiveColor: Color {
        return Color(rawValue: color) ?? .gray
    }
}

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

struct AddColorAndDownloadsToShortcut: PostgreSQLMigration {
    
    static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return Database.update(Shortcut.self, on: conn) { builder in
            builder.field(for: \.color, type: .bigint, .default(.literal(0)))
            builder.field(for: \.downloads, type: .bigint, .default(.literal(0)))
        }
    }
    
    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return Database.update(Shortcut.self, on: conn) { builder in
            builder.deleteField(for: \.color)
            builder.deleteField(for: \.downloads)
        }
    }
    
}

struct AddFileHashToShortcut: PostgreSQLMigration {
    
    static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return Database.update(Shortcut.self, on: conn) { builder in
            builder.field(for: \.fileHash, type: .char(32), .default(.literal("")))
        }
    }
    
    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return Database.update(Shortcut.self, on: conn) { builder in
            builder.deleteField(for: \.fileHash)
        }
    }
    
}
