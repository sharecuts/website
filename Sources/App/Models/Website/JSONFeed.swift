//
//  JSONFeed.swift
//  App
//
//  Created by Guilherme Rambo on 07/10/18.
//

import Foundation
import Vapor

struct JSONFeed: Codable {
    static let currentVersion = "https://jsonfeed.org/version/1"

    let version: String
    let title: String
    let home_page_url: String
    let feed_url: String
    let favicon: String
    let items: [Item]
    
    struct Item: Codable {
        let id: String
        let title: String
        let content_text: String
        let url: String
        let author: Author
        
        init(id: String, title: String, content_text: String, url: String, author: Author) {
            self.id = id
            self.title = title
            self.content_text = content_text
            self.url = url
            self.author = author
        }
    }
    
    struct Author: Codable {
        let name: String
        let url: String
        
        init(name: String, url: String) {
            self.name = name
            self.url = url
        }
    }
    
    init(version: String,
         title: String,
         home_page_url: String,
         feed_url: String,
         favicon: String,
         items: [Item])
    {
        self.version = version
        self.title = title
        self.home_page_url = home_page_url
        self.feed_url = feed_url
        self.favicon = favicon
        self.items = items
    }
}

extension JSONFeed: Content { }
extension JSONFeed.Item: Content { }

extension JSONFeed {
    
    init(cards: [ShortcutCard]) throws {
        self.items = try cards.map(Item.init)
        self.version = JSONFeed.currentVersion
        self.title = "Sharecuts"
        self.home_page_url = "https://sharecuts.app"
        self.feed_url = "https://sharecuts.app/feed.json"
        self.favicon = "https://sharecuts.app/assets/img/sharecuts-ios-icon.png"
    }
    
}

extension JSONFeed.Item {
    
    init(card: ShortcutCard) throws {
        self.id = try card.shortcut.requireID().uuidString
        self.title = card.shortcut.title
        self.content_text = card.shortcut.summary
        self.url = card.downloadLink
        self.author = JSONFeed.Author(
            name: card.creator.name,
            url: "https://sharecuts.app/users/\(card.creator.username)"
        )
    }
    
}
