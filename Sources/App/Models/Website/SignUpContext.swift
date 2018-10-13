//
//  SignUpContext.swift
//  App
//
//  Created by Guilherme Rambo on 10/10/18.
//

import Foundation
import Vapor

struct SignUpContext: Codable {
    let invite: Invite?
    let partialUser: User?
    let error: String?
    let validationMessage: String?
    
    init(error: String? = nil,
        partialUser: User? = nil,
        invite: Invite? = nil,
        validationMessage: String? = nil)
    {
        self.invite = invite
        self.error = error
        self.partialUser = partialUser
        self.validationMessage = validationMessage
    }
}
