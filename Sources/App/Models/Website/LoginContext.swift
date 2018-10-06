//
//  LoginContext.swift
//  App
//
//  Created by Guilherme Rambo on 06/10/18.
//

import Foundation
import Vapor

struct LoginContext: Codable {
    let isError: Bool
    
    init(error: Bool) {
        self.isError = error
    }
}
