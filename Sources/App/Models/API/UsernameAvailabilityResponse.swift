//
//  UsernameAvailabilityResponse.swift
//  App
//
//  Created by Guilherme Rambo on 10/10/18.
//

import Foundation
import Vapor

struct UsernameAvailabilityResponse: Codable {
    let username: String
    let isAvailable: Bool
    let message: String
    
    init(username: String, isAvailable: Bool, message: String) {
        self.username = username
        self.isAvailable = isAvailable
        self.message = message
    }
}

extension UsernameAvailabilityResponse: Content { }
