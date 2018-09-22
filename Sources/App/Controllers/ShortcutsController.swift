//
//  ShortcutsController.swift
//  App
//
//  Created by Guilherme Rambo on 07/07/18.
//

import Foundation
import Vapor
import FluentPostgreSQL

final class ShortcutsController: RouteCollection {

    func boot(router: Router) throws {
        let shortcutsRoute = router.grouped("api", "shortcuts")

        shortcutsRoute.get("latest", use: latest)
        shortcutsRoute.post("/", use: create)
        shortcutsRoute.delete("/", Shortcut.parameter, use: delete)
        shortcutsRoute.get("/", Shortcut.parameter, use: details)
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

    func create(_ req: Request) throws -> Future<ModifyShortcutResponse> {
        let queryKey = try? req.query.get(String.self, at: ["apiKey"])

        guard let apiKey = req.http.headers["X-Shortcuts-Key"].first ?? queryKey else {
            throw Abort(.forbidden)
        }

        let userQuery = User.query(on: req).filter(\.apiKey, .equal, apiKey).first()

        return userQuery.flatMap(to: Shortcut.self) { user in
            guard let userID = user?.id else {
                throw Abort(.forbidden)
            }

            let request = try req.content.decode(CreateShortcutRequest.self)

            return request.flatMap(to: Shortcut.self) { requestData in
                let decoder = PropertyListDecoder()
                let shortcutFile = try decoder.decode(ShortcutFile.self, from: requestData.shortcut.data)

                guard shortcutFile.isValid else {
                    throw Abort(.badRequest)
                }

                let upload = B2Client.shared.upload(on: req, file: requestData.shortcut, info: shortcutFile)

                return upload.flatMap { result in
                    let shortcut = Shortcut(
                        userID: userID,
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
        }.map(to: ModifyShortcutResponse.self) { shortcut in
            return ModifyShortcutResponse(id: shortcut.id)
        }
    }

    func delete(_ req: Request) throws -> Future<ModifyShortcutResponse> {
        guard let apiKey = req.http.headers["X-Shortcuts-Key"].first else {
            throw Abort(.forbidden)
        }

        let userQuery = User.query(on: req).filter(\.apiKey, .equal, apiKey).first()

        return userQuery.flatMap(to: Shortcut.self) { user in
            guard let userID = user?.id else {
                throw Abort(.forbidden)
            }

            let shortcutParam = try req.parameters.next(Shortcut.self)

            return shortcutParam.map { shortcut in
                guard shortcut.userID == userID else {
                    throw Abort(.forbidden)
                }

                return shortcut
            }.thenIfErrorThrowing { _ in
                throw Abort(.notFound)
            }
        }.flatMap(to: ModifyShortcutResponse.self) { shortcut in
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
