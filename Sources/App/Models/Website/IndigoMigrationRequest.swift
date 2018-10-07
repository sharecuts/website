//
//  IndigoMigrationRequest.swift
//  App
//
//  Created by Guilherme Rambo on 06/10/18.
//

import Foundation
import Vapor

struct IndigoMigrationRequest: Codable {
    let username: String
    let apiKey: String
    let password: String
    let password2: String
}
