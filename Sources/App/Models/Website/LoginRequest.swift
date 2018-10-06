//
//  LoginRequest.swift
//  App
//
//  Created by Guilherme Rambo on 06/10/18.
//

import Foundation
import Vapor

struct LoginRequest: Content {
    let username: String
    let password: String
}
