//
//  UploadContext.swift
//  App
//
//  Created by Guilherme Rambo on 06/10/18.
//

import Foundation
import Vapor

struct UploadContext: Codable {
    let user: User
    let firstName: String?
    
    init(_ user: User) {
        self.user = user
        self.firstName = user.firstName
    }
}
