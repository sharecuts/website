//
//  TagsResponse.swift
//  App
//
//  Created by Guilherme Rambo on 06/10/18.
//

import Foundation
import Vapor

struct TagsResponse: Codable {
    let count: Int
    let results: [Tag]
    let error: Bool
    let reason: String?
    
    init(results: [Tag]) {
        self.results = results
        self.count = results.count
        self.error = false
        self.reason = nil
    }
    
    init(errorReason: String) {
        self.error = true
        self.reason = errorReason
        self.count = 0
        self.results = []
    }
}

extension TagsResponse: Content { }
