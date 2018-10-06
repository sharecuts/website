//
//  Tag.swift
//  App
//
//  Created by Guilherme Rambo on 06/10/18.
//

import Foundation
import Vapor
import FluentPostgreSQL

final class Tag: Codable {
    
    static let utilityTagID = UUID(uuidString: "2F46B7B4-A9FC-45F6-BA23-717CEF56CE74")!
    
    var id: UUID?
    let name: String
    let emoji: String
    let slug: String
    
    var shortcuts: Children<Tag, Shortcut> {
        return children(\.tagID)
    }
    
    init(id: UUID? = nil, name: String, emoji: String, slug: String) {
        self.id = id ?? UUID()
        self.name = name
        self.emoji = emoji
        self.slug = slug
    }
    
}

extension Tag: PostgreSQLUUIDModel { }
extension Tag: Content { }
extension Tag: Migration { }
extension Tag: Parameter { }

struct CreateDefaultTags: PostgreSQLMigration {
    
    static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        let tags = [
            Tag(name: "Productivity", emoji: "🖥", slug: "productivity"),
            Tag(name: "Fun", emoji: "🎮", slug: "fun"),
            Tag(name: "Developer", emoji: "📲", slug: "developer"),
            Tag(name: "News", emoji: "🗞", slug: "news"),
            Tag(name: "Photo & Video", emoji: "📷", slug: "photo-video"),
            Tag(name: "Music", emoji: "🎹", slug: "music"),
            Tag(name: "Home", emoji: "🏠", slug: "home"),
            Tag(id: Tag.utilityTagID, name: "Utility", emoji: "🛠", slug: "utility")
        ]
        
        return tags.map({ $0.save(on: conn) }).map(to: Void.self, on: conn, { _ in })
    }
    
    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return Future.map(on: conn, { })
    }
    
}
