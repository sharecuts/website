//
//  ShortcutDetailsResponse.swift
//  App
//
//  Created by Guilherme Rambo on 06/10/18.
//

import Foundation
import Vapor

struct ShortcutDetailsResponse: Codable {
    let shortcut: Shortcut
    let user: User.Public
    let deepLink: URL
    let download: URL
    
    init(shortcut: Shortcut, user: User) throws {
        self.shortcut = shortcut
        self.user = user.publicView
        self.deepLink = try shortcut.generateDeepLinkURL()
        self.download = try shortcut.generateDownloadURL()
    }
}

extension ShortcutDetailsResponse: Content { }
