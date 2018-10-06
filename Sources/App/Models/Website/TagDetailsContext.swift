//
//  TagDetailsContext.swift
//  App
//
//  Created by Guilherme Rambo on 06/10/18.
//

import Foundation
import Vapor

struct TagDetailsContext: Codable {
    let navigation: NavigationContext
    let tag: Tag
    let cards: [ShortcutCard]
    let cardCount: Int
    
    init(navigation: NavigationContext, tag: Tag, cards: [ShortcutCard]) {
        self.navigation = navigation
        self.tag = tag
        self.cards = cards
        self.cardCount = cards.count
    }
}
