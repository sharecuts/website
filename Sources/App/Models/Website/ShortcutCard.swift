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
    let downloadLink: String
    let actionCountSuffix: String
    let voted: Bool
    
    init(_ shortcut: Shortcut, users: [User], req: Request) throws {
        self.shortcut = shortcut
        
        guard let user = users.first(where: { $0.id == shortcut.userID }) else {
            throw Abort(.notFound)
        }
        
        self.creator = user
        
        self.deepLink = try shortcut.generateDeepLinkURL().absoluteString
        self.downloadLink = try shortcut.generateDownloadURL().absoluteString
        self.actionCountSuffix = shortcut.actionCount > 1 ? "actions" : "action"
        self.voted = try shortcut.isInVotingCookie(with: req)
    }
}

extension ShortcutCard: Content { }
