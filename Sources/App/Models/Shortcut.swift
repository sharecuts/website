//
//  Shortcut.swift
//  App
//
//  Created by Guilherme Rambo on 07/07/18.
//

import Foundation
import Vapor
import FluentPostgreSQL

final class Shortcut: Codable {

    var id: UUID?
    var createdAt: Date
    var updatedAt: Date
    var userID: User.ID

    var title: String
    var summary: String

    var filePath: String
    var fileID: String
    var actionCount: Int
    var actionIdentifiers: [String]

    var user: Parent<Shortcut, User> {
        return parent(\.userID)
    }

    init(userID: User.ID,
         title: String,
         summary: String,
         filePath: String,
         fileID: String,
         actionCount: Int,
         actionIdentifiers: [String])
    {
        self.createdAt = Date()
        self.updatedAt = Date()
        self.userID = userID
        self.title = title
        self.summary = summary
        self.filePath = filePath
        self.fileID = fileID
        self.actionCount = actionCount
        self.actionIdentifiers = actionIdentifiers
    }
}

extension Shortcut: PostgreSQLUUIDModel { }
extension Shortcut: Content { }
extension Shortcut: Migration { }
extension Shortcut: Parameter { }

extension Shortcut: OwnedByUser { }
