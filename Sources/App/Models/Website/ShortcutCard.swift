//
//  ShortcutCard.swift
//  App
//
//  Created by Guilherme Rambo on 06/10/18.
//

import Foundation
import Vapor

struct ShortcutCard: Codable {
    let shortcut: Shortcut
    let creator: User
    let deepLink: String
    let actionCountSuffix: String
    
    init(_ shortcut: Shortcut, users: [User]) throws {
        self.shortcut = shortcut
        
        guard let user = users.first(where: { $0.id == shortcut.userID }) else {
            throw Abort(.notFound)
        }
        
        self.creator = user
        
        self.deepLink = try shortcut.generateDeepLinkURL().absoluteString
        self.actionCountSuffix = shortcut.actionCount > 1 ? "actions" : "action"
    }
}

extension ShortcutCard: Content { }
