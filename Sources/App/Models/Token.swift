//
//  Token.swift
//  App
//
//  Created by Guilherme Rambo on 06/10/18.
//

import Foundation
import Vapor
import FluentPostgreSQL
import Authentication

final class Token: Codable {
    var id: UUID?
    var token: String
    var userID: User.ID
    
    init(token: String, userID: User.ID) {
        self.token = token
        self.userID = userID
    }
}

extension Token: PostgreSQLUUIDModel {}
extension Token: Migration {}
extension Token: Content {}

extension Token {
    
    static func generate(for user: User) throws -> Token {
        let random = try CryptoRandom().generateData(count: 128)
        
        return try Token(
            token: random.base64EncodedString(),
            userID: user.requireID()
        )
    }
    
}

extension Token: Authentication.Token {
    static var userIDKey: WritableKeyPath<Token, Token.UserIDType> = \Token.userID
    
    typealias UserType = User
}

extension Token: BearerAuthenticatable {
    static var tokenKey: WritableKeyPath<Token, String> = \Token.token
}
