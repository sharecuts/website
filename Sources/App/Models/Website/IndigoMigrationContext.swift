//
//  IndigoMigrationContext.swift
//  App
//
//  Created by Guilherme Rambo on 06/10/18.
//

import Foundation
import Vapor

struct IndigoMigrationContext: Codable {
    let user: User?
    let apiKey: String?
    let error: String?
    
    init(user: User? = nil, apiKey: String? = nil, error: String? = nil) {
        self.user = user
        self.apiKey = apiKey
        self.error = error
    }
}
