//
//  Invite.swift
//  App
//
//  Created by Guilherme Rambo on 10/10/18.
//

import Foundation
import Vapor
import FluentPostgreSQL
import Authentication

final class Invite: Codable {
    var id: UUID?
    var code: String
    var usedAt: Date?
    
    init() throws {
        self.code = try CryptoRandom().generateData(count: 64).hexEncodedString()
        self.id = nil
        self.usedAt = nil
    }
}

extension Invite: PostgreSQLUUIDModel {}
extension Invite: Migration {}
extension Invite: Content {}
