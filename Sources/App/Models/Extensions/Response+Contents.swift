//
//  Response+Contents.swift
//  App
//
//  Created by Guilherme Rambo on 06/10/18.
//

import Foundation
import Vapor

extension Response {
    
    convenience init<T: Encodable>(contents: T, in container: Container) throws {
        let data = try JSONEncoder().encode(contents)
        
        self.init(contents: data, in: container)
    }
    
    convenience init(contents: Data, in container: Container, with contentType: String = "application/json") {
        let headers = HTTPHeaders([
            ("Content-Type", "\(contentType); charset=utf-8")
        ])
        
        let http = HTTPResponse(
            status: .ok,
            version: HTTPVersion(major: 2, minor: 0),
            headers: headers,
            body: contents
        )
        
        self.init(http: http, using: container)
    }
    
}
