//
//  SignupData.swift
//  App
//
//  Created by Guilherme Rambo on 10/10/18.
//

import Foundation
import Vapor

struct SignupData: Codable {
    let name: String
    let username: String
    let url: String
    let password: String
    let password2: String
    let invite: String
}

extension SignupData: Content { }
