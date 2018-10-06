//
//  ModifyShortcutResponse.swift
//  App
//
//  Created by Guilherme Rambo on 06/10/18.
//

import Foundation
import Vapor

struct ModifyShortcutResponse: Codable {
    let id: Shortcut.ID?
    let error: Bool
    let reason: String?
    
    init(error: Bool = false, id: Shortcut.ID?, reason: String? = nil) {
        self.error = error
        self.reason = reason
        self.id = id
    }
}

extension ModifyShortcutResponse: Content { }
