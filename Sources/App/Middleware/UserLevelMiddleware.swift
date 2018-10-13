//
//  UserLevelMiddleware.swift
//  App
//
//  Created by Guilherme Rambo on 10/10/18.
//

import Foundation
import Vapor

final class UserLevelMiddleware: Middleware {
    
    let level: User.Level
    
    init(level: User.Level) {
        self.level = level
    }
    
    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        let user = try request.requireAuthenticated(User.self)
        
        guard user.level == level else {
            let logger = try request.make(Logger.self)
            
            logger.error("Unauthorized access attempt to \(request.http.url) by user \(user.username) (ID: \(try user.requireID()))")
            
            throw Abort(.unauthorized, reason: "The logged in user doesn't have access to this feature. This incident will be reported.")
        }
        
        return try next.respond(to: request)
    }
    
}
