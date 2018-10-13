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

extension SignupData {
    
    // I tried using Vapor's built-in validation, but the error messages suck
    
    var validationErrors: [String] {
        var r: [String] = []
        
        if let data = username.data(using: .ascii, allowLossyConversion: true), let str = String(data: data, encoding: .ascii) {
            if str != username {
                r.append("Username must contain only ASCII characters")
            }
        }
        
        if password.count < 8 {
            r.append("Your password must be at least 8 characters long")
        }
        
        if password != password2 {
            r.append("The passwords must match")
        }
        
        if username.count < 3 || username.count > 20 {
            r.append("Username must be between 3 and 20 characters long")
        }
        
        if URL(string: url)?.scheme?.lowercased() != "https" {
            r.append("The website URL must be a valid HTTPS URL")
        }
        
        return r
    }
    
}
