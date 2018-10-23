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
    let creator: User.Public
    let deepLink: String
    let downloadLink: String
    let actionCountSuffix: String
    let voted: Bool
    let colorName: String
    let colorCode: String?
    
    init(_ shortcut: Shortcut, users: [User], req: Request) throws {
        self.shortcut = shortcut
        
        guard let user = users.first(where: { $0.id == shortcut.userID }) else {
            throw Abort(.notFound)
        }
        
        self.creator = user.publicView
        
        self.deepLink = try shortcut.generateDeepLinkURL().absoluteString
        self.downloadLink = try shortcut.generateDownloadURL().absoluteString
        self.actionCountSuffix = shortcut.actionCount > 1 ? "actions" : "action"
        self.voted = try shortcut.isInVotingCookie(with: req)
        self.colorName = shortcut.effectiveColor.name
        self.colorCode = shortcut.effectiveColor.rawValue.rgbColorCode
    }
}

extension ShortcutCard: Content { }

private extension Int {

    var rgbColorCode: String? {
        let str = String(format: "%02X", self)

        guard str.count > 6 else { return str }

        let lastIndex = str.index(str.startIndex, offsetBy: 6)

        return String(str[str.startIndex..<lastIndex])
    }

}
