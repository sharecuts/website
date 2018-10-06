//
//  HomeContext.swift
//  App
//
//  Created by Guilherme Rambo on 06/10/18.
//

import Foundation
import Vapor

struct HomeContext: Codable {
    let navigation: NavigationContext
    let cards: [ShortcutCard]
    
    init(navigation: NavigationContext, cards: [ShortcutCard]) {
        self.navigation = navigation
        self.cards = cards
    }
}
