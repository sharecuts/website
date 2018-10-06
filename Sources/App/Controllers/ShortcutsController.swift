//
//  ShortcutsController.swift
//  App
//
//  Created by Guilherme Rambo on 07/07/18.
//

import Foundation
import Vapor
import FluentPostgreSQL
import Crypto
import Authentication

final class ShortcutsController: RouteCollection {

    func boot(router: Router) throws {
        let tokenAuth = User.tokenAuthMiddleware()
        let sessionAuth = User.authSessionsMiddleware()
        let guardAuth = User.guardAuthMiddleware()
        
        let shortcutsRoutes = router.grouped("api", "shortcuts")
        
        let protectedByTokenOnly = shortcutsRoutes.grouped(tokenAuth, guardAuth)
        let protectedBySessionAndToken = shortcutsRoutes.grouped(tokenAuth, sessionAuth, guardAuth)

        protectedBySessionAndToken.post("/", use: create)
        protectedByTokenOnly.delete("/", Shortcut.parameter, use: delete)

        shortcutsRoutes.get("latest", use: latest)
        shortcutsRoutes.get("/", Shortcut.parameter, use: details)
        
        shortcutsRoutes.put(Shortcut.parameter, "vote", use: vote)
        shortcutsRoutes.get(Shortcut.parameter, "votes", use: votes)
    }

    func latest(_ req: Request) throws -> Future<QueryShortcutsResponse> {
        let query = Shortcut.query(on: req).range(0...30).sort(\.createdAt, .descending).all()

        return query.map(to: QueryShortcutsResponse.self) { shortcuts in
            return QueryShortcutsResponse(results: shortcuts)
        }
    }

    func details(_ req: Request) throws -> Future<ShortcutDetailsResponse> {
        let shortcutParam = try req.parameters.next(Shortcut.self)

        return shortcutParam.flatMap(to: ShortcutDetailsResponse.self) { shortcut in
            let userQuery = shortcut.user.query(on: req).first()
            
            return userQuery.map(to: ShortcutDetailsResponse.self) { user in
                guard let user = user else {
                    throw Abort(.notFound)
                }

                return try ShortcutDetailsResponse(shortcut: shortcut, user: user)
            }
        }.thenIfErrorThrowing { _ in
            throw Abort(.notFound)
        }
    }

    func create(_ req: Request) throws -> Future<Response> {
        let user = try req.requireAuthenticated(User.self)

        let request = try req.content.decode(CreateShortcutRequest.self)
        
        let shortcutCreation = request.flatMap(to: Shortcut.self) { requestData in
            let decoder = PropertyListDecoder()
            let shortcutFile = try decoder.decode(ShortcutFile.self, from: requestData.shortcut.data)
            
            guard shortcutFile.isValid else {
                throw Abort(.badRequest)
            }
            
            let upload = B2Client.shared.upload(on: req, file: requestData.shortcut, info: shortcutFile)
            
            return upload.flatMap { result in
                let shortcut = try Shortcut(
                    userID: user.requireID(),
                    title: requestData.title,
                    summary: requestData.summary,
                    filePath: result.fileName,
                    fileID: result.fileId,
                    actionCount: shortcutFile.actions.count,
                    actionIdentifiers: shortcutFile.actions.map({ $0.identifier })
                )
                
                // Purge homepage cache
                let cfClient = try req.make(CloudFlareClient.self)
                cfClient.purgeCache(at: "/")
                
                return shortcut.save(on: req)
            }
        }
        
        if req.isWebsiteRequest {
            return shortcutCreation.map(to: Response.self) { _ in
                return req.redirect(to: "/")
            }
        } else {
            let apiResponse = shortcutCreation.map(to: ModifyShortcutResponse.self) { shortcut in
                return ModifyShortcutResponse(id: shortcut.id)
            }
            
            return apiResponse.map(to: Response.self, { try Response(contents: $0, in: req) })
        }
    }

    func delete(_ req: Request) throws -> Future<ModifyShortcutResponse> {
        let user = try req.requireAuthenticated(User.self)

        let shortcutParam = try req.parameters.next(Shortcut.self)
        
        return shortcutParam.flatMap(to: ModifyShortcutResponse.self) { shortcut in
            guard try shortcut.isOwned(by: user) else {
                throw Abort(.unauthorized)
            }
            
            let deleteFromBucket = B2Client.shared.delete(on: req, shortcut: shortcut)
            
            return deleteFromBucket.flatMap { _ in
                return shortcut.delete(on: req).map(to: ModifyShortcutResponse.self) {
                    // Purge homepage cache
                    let cfClient = try req.make(CloudFlareClient.self)
                    cfClient.purgeCache(at: "/")
                    
                    return ModifyShortcutResponse(id: shortcut.id)
                }
            }
        }
    }
    
    func vote(_ req: Request) throws -> Future<VotingResponse> {
        let shortcutParam = try req.parameters.next(Shortcut.self)

        let client = try req.make(VotingClient.self)
        
        return shortcutParam.flatMap { shortcut in
            return try client.vote(for: shortcut.requireID())
        }
    }
    
    func votes(_ req: Request) throws -> Future<VotingResponse> {
        let shortcutParam = try req.parameters.next(Shortcut.self)
        
        let client = try req.make(VotingClient.self)
        
        return shortcutParam.flatMap { shortcut in
            return try client.getVotes(for: shortcut.requireID())
        }
    }

}

struct CreateShortcutRequest: Codable {
    let title: String
    let summary: String
    let shortcut: File
}

extension CreateShortcutRequest: Content { }

struct ModifyShortcutResponse: Codable {
    let id: Shortcut.ID?
    let error: Bool
    let reason: String?

    init(error: Bool = false, id: Shortcut.ID?, reason: String? = nil) {
        self.error = error
        self.reason = reason
        self.id = id
    }
}

extension ModifyShortcutResponse: Content { }

struct QueryShortcutsResponse: Codable {
    let count: Int
    let results: [Shortcut]
    let error: Bool
    let reason: String?

    init(results: [Shortcut]) {
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

extension QueryShortcutsResponse: Content { }

struct ShortcutDetailsResponse: Codable {
    let shortcut: Shortcut
    let user: User.Public
    let deepLink: URL
    let download: URL

    init(shortcut: Shortcut, user: User) throws {
        self.shortcut = shortcut
        self.user = user.publicView
        self.deepLink = try shortcut.generateDeepLinkURL()
        self.download = try shortcut.generateDownloadURL()
    }
}

extension ShortcutDetailsResponse: Content { }

extension Request {
    
    var isWebsiteRequest: Bool {
        let acceptedTypes = http.headers["accept"]
        
        return acceptedTypes.contains(where: { $0.lowercased().contains("text/html") })
    }
    
}
