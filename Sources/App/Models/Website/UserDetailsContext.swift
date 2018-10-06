//
//  UserDetailsContext.swift
//  App
//
//  Created by Guilherme Rambo on 06/10/18.
//

import Foundation
import Vapor

struct UserDetailsContext: Codable {
    let user: User
    let cards: [ShortcutCard]
    
    init(user: User, cards: [ShortcutCard]) {
        self.user = user
        self.cards = cards
    }
}
