//
//  RegistrationContext.swift
//  App
//
//  Created by Guilherme Rambo on 10/10/18.
//

import Foundation
import Vapor

struct RegistrationContext: Codable {
    let invite: Invite?
    let partialUser: User?
    let error: String?
    
    init(error: String? = nil, partialUser: User? = nil, invite: Invite? = nil) {
        self.invite = invite
        self.error = error
        self.partialUser = partialUser
    }
}
