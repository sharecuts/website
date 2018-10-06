//
//  NavigationContext.swift
//  App
//
//  Created by Guilherme Rambo on 06/10/18.
//

import Foundation
import Vapor

struct NavigationContext: Codable {
    let tags: [Tag]
    let activeTag: Tag?
    
    init(tags: [Tag], activeTag: Tag? = nil) {
        self.tags = tags
        self.activeTag = activeTag
    }
}
