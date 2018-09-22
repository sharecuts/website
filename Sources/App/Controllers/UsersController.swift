//
//  UsersController.swift
//  App
//
//  Created by Guilherme Rambo on 07/07/18.
//

import Foundation
import Vapor
import FluentPostgreSQL
import Crypto

final class UsersController: RouteCollection {

    let masterKey: String

    init(masterKey: String) {
        self.masterKey = masterKey
    }

    func boot(router: Router) throws {
        let usersRoute = router.grouped("api", "users")
        usersRoute.post(User.CreateRequest.self, use: create)
        usersRoute.get(User.parameter, use: get)
    }

    func get(_ req: Request) throws -> Future<User.Public> {
        do {
            let fetchUser = try req.parameters.next(User.self)

            return fetchUser.map(to: User.Public.self) { user in
                return user.publicView
            }.thenIfErrorThrowing { _ in
                throw Abort(.notFound)
            }
        } catch {
            throw Abort(.notFound)
        }
    }

    func create(_ req: Request, user: User.CreateRequest) throws -> Future<User.Public> {
        guard let masterKey = req.http.headers["X-ShortcutSharing-Master-Key"].first else {
            throw Abort(.forbidden)
        }

        let isAuthenticatedAsMaster = (masterKey == self.masterKey)

        guard isAuthenticatedAsMaster else {
            throw Abort(.forbidden)
        }

        let createRequest = try req.content.decode(User.CreateRequest.self)

        return createRequest.flatMap { data in
            let passwordHash = try BCrypt.hash(data.password)
            let keyHash = try BCrypt.hash(data.apiKey)

            let newUser = User(
                id: nil,
                name: data.name,
                username: data.username,
                password: passwordHash,
                url: data.url,
                apiKey: keyHash
            )

            // I know this doesn't make sense currently, but in the future users will be able to
            // register by themselves, but only master can set the level of a user
            if isAuthenticatedAsMaster, let rawLevel = data.rawLevel {
                newUser.rawLevel = rawLevel
            }

            return newUser.save(on: req).map { $0.publicView }
        }
    }

}
