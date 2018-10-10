//
//  InvitesController.swift
//  App
//
//  Created by Guilherme Rambo on 10/10/18.
//

import Foundation
import Vapor
import FluentPostgreSQL
import Crypto
import Authentication

final class InvitesController: RouteCollection {

    func boot(router: Router) throws {
        let invitesRoute = router.grouped("api", "invites")
        
        let tokenAuth = User.tokenAuthMiddleware()
        let guardAuth = User.guardAuthMiddleware()
        
        let adminAuth = UserLevelMiddleware(level: .administrator)
        let adminRoutes = invitesRoute.grouped([tokenAuth, guardAuth, adminAuth])
        
        adminRoutes.post("/", use: create)
    }
    
    func create(_ req: Request) throws -> Future<Invite> {
        let invite = try Invite()
        
        return invite.save(on: req)
    }
    
}
