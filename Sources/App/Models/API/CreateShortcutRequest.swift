//
//  CreateShortcutRequest.swift
//  App
//
//  Created by Guilherme Rambo on 06/10/18.
//

import Foundation
import Vapor

struct CreateShortcutRequest: Codable {
    let tagID: UUID
    let title: String
    let summary: String
    let shortcut: File?
    let shortcutURL: String?
}

extension CreateShortcutRequest: Content { }

extension CreateShortcutRequest {

    var isFileUploadRequest: Bool {
        return shortcut != nil
    }

}
