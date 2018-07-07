//
//  ShortcutFile.swift
//  App
//
//  Created by Guilherme Rambo on 07/07/18.
//

import Foundation

struct ShortcutFile: Codable {
    struct ShortcutAction: Codable {
        let identifier: String

        enum CodingKeys: String, CodingKey {
            case identifier = "WFWorkflowActionIdentifier"
        }
    }

    let clientVersion: String
    let clientRelease: String
    let actions: [ShortcutAction]

    enum CodingKeys: String, CodingKey {
        case clientVersion = "WFWorkflowClientVersion"
        case clientRelease = "WFWorkflowClientRelease"
        case actions = "WFWorkflowActions"
    }
}

extension ShortcutFile {
    var isValid: Bool {
        return !clientVersion.isEmpty && !clientRelease.isEmpty && !actions.isEmpty
    }
}
