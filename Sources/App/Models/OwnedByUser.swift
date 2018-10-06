//
//  OwnedByUser.swift
//  App
//
//  Created by Guilherme Rambo on 06/10/18.
//

import Foundation

protocol OwnedByUser {
    var userID: User.ID { get }
    func isOwned(by user: User) throws -> Bool
}

extension OwnedByUser {
    
    /// Returns whether this object is owned by the specified user
    func isOwned(by user: User) throws -> Bool {
        return try user.requireID() == userID
    }
    
}
