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
    
    let masterKey: String
    
    init(masterKey: String) {
        assert(!masterKey.isEmpty)
        
        self.masterKey = masterKey
    }
    
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
        
        shortcutsRoutes.patch(Shortcut.parameter, "tag", use: assignTag)
        
        let tagsRoutes = router.grouped("api", "tags")
        
        tagsRoutes.get("", use: tags)
        tagsRoutes.get(String.parameter, use: tag)
    }

    func latest(_ req: Request) throws -> Future<QueryShortcutsResponse> {
        let query = Shortcut.query(on: req).range(0...50).sort(\.createdAt, .descending).all()

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
                    tagID: requestData.tagID,
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
            }.thenIfErrorThrowing { error in
                let error = "Make sure you have entered all the information required, including the category.".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    
                return req.redirect(to: "/upload?error=\(error)")
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
    
    // MARK: - Voting
    
    private let useExternalServiceForVoting = false
    
    func vote(_ req: Request) throws -> Future<VotingResponse> {
        guard !useExternalServiceForVoting else {
            return try voteUsingExternalService(req)
        }
        
        let shortcutParam = try req.parameters.next(Shortcut.self)
        
        return shortcutParam.flatMap { shortcut in
            let voted = try shortcut.isInVotingCookie(with: req)
            
            guard !voted else {
                throw Abort(.forbidden)
            }

            let mutableShortcut = shortcut
            
            mutableShortcut.votes += 1
            
            return mutableShortcut.save(on: req).map(to: VotingResponse.self) { updatedShortcut in
                try shortcut.addToVotingCookie(with: req)

                return try VotingResponse(shortcut: updatedShortcut)
            }
        }
    }
    
    func votes(_ req: Request) throws -> Future<VotingResponse> {
        let shortcutParam = try req.parameters.next(Shortcut.self)
        
        return shortcutParam.map(to: VotingResponse.self) { shortcut in
            return try VotingResponse(shortcut: shortcut)
        }
    }
    
    func voteUsingExternalService(_ req: Request) throws -> Future<VotingResponse> {
        let shortcutParam = try req.parameters.next(Shortcut.self)
        
        let client = try req.make(VotingClient.self)
        
        return shortcutParam.flatMap { shortcut in
            return try client.vote(for: shortcut.requireID())
        }
    }
    
    func fetchVotesUsingExternalService(_ req: Request) throws -> Future<VotingResponse> {
        let shortcutParam = try req.parameters.next(Shortcut.self)
        
        let client = try req.make(VotingClient.self)
        
        return shortcutParam.flatMap { shortcut in
            return try client.getVotes(for: shortcut.requireID())
        }
    }
    
    // MARK: - Tags
    
    func tags(_ req: Request) throws -> Future<TagsResponse> {
        return Tag.query(on: req).sort(\.name).all().map(to: TagsResponse.self) { tags in
            return TagsResponse(results: tags)
        }
    }
    
    func tag(_ req: Request) throws -> Future<QueryShortcutsResponse> {
        let tagSlug = try req.parameters.next(String.self)
        
        let tagQuery = Tag.query(on: req).filter(\.slug, .equal, tagSlug).first()
        
        return tagQuery.flatMap { tag in
            guard let tag = tag else {
                throw Abort(.notFound)
            }
            
            return try tag.shortcuts.query(on: req).all().map(to: QueryShortcutsResponse.self) { shortcuts in
                return QueryShortcutsResponse(results: shortcuts)
            }
        }
    }
    
    func assignTag(_ req: Request) throws -> Future<Shortcut> {
        guard let masterKey = req.http.headers["X-ShortcutSharing-Master-Key"].first else {
            throw Abort(.forbidden)
        }
        
        let isAuthenticatedAsMaster = (masterKey == self.masterKey)
        
        guard isAuthenticatedAsMaster else {
            throw Abort(.forbidden)
        }
        
        let shortcut = try req.parameters.next(Shortcut.self)
        
        return shortcut.flatMap { shortcut in
            let changeTagReq = try req.content.decode(ChangeTagRequest.self)
            
            return changeTagReq.flatMap(to: Shortcut.self) { changeTag in
                let query = Tag.query(on: req).filter(\.slug, .equal, changeTag.tag).first()
                
                return query.flatMap(to: Shortcut.self) { tag in
                    guard let tag = tag else {
                        throw Abort(.notFound)
                    }
                    
                    shortcut.tagID = try tag.requireID()
                    
                    return shortcut.save(on: req)
                }
            }
        }
    }

}

extension Request {
    
    var isWebsiteRequest: Bool {
        let acceptedTypes = http.headers["accept"]
        
        return acceptedTypes.contains(where: { $0.lowercased().contains("text/html") })
    }
    
}
