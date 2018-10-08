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
    let icon: ShortcutIcon
    
    var color: Color {
        return Color(rawValue: icon.color) ?? .gray
    }

    enum CodingKeys: String, CodingKey {
        case clientVersion = "WFWorkflowClientVersion"
        case clientRelease = "WFWorkflowClientRelease"
        case actions = "WFWorkflowActions"
        case icon = "WFWorkflowIcon"
    }
}

struct ShortcutIcon: Codable {
    let color: Int
    let imageData: Data
    let glyphNumber: Int
    
    enum CodingKeys: String, CodingKey {
        case color = "WFWorkflowIconStartColor"
        case imageData = "WFWorkflowIconImageData"
        case glyphNumber = "WFWorkflowIconGlyphNumber"
    }
}

enum Color: Int, Hashable, Equatable, Codable, CaseIterable {
    case gray = 0xA9A9A9FF
    case yellow = 0xFEC418FF
    case red = 0xFF4351FF
    case blue = 0x3871DEFF
    case green = 0xFFD426FF
    case purple = 0xDB49D8FF
    case orange = 0xFE9949FF
    case pink = 0xED4694FF
    case lightBlue = 0x1B9AF7FF
    case darkGray = 255
    
    static func validColorOrRandom(from color: Int) -> Int {
        if Color(rawValue: color) != nil {
            return color
        } else {
            return Color.allCases.shuffled()[0].rawValue
        }
    }
}

extension Color {
    var name: String {
        switch self {
        case .gray: return "gray"
        case .yellow: return "yellow"
        case .red: return "red"
        case .blue: return "blue"
        case .green: return "green"
        case .purple: return "purple"
        case .orange: return "orange"
        case .pink: return "pink"
        case .lightBlue: return "lightBlue"
        case .darkGray: return "darkGray"
        }
    }
}

extension ShortcutFile {
    var isValid: Bool {
        return !clientVersion.isEmpty && !clientRelease.isEmpty && !actions.isEmpty
    }
}
