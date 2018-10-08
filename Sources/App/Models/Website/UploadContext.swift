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
    let tags: [Tag]
    let error: String?
    
    init(_ user: User, tags: [Tag], error: String? = nil) {
        self.user = user
        self.firstName = user.firstName
        self.tags = tags
        self.error = error
    }
}
