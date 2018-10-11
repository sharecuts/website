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
import Authentication

final class UsersController: RouteCollection {

    let masterKey: String

    init(masterKey: String) {
        assert(!masterKey.isEmpty)

        self.masterKey = masterKey
    }

    func boot(router: Router) throws {
        // REST API authentication call
        
        let usersRoute = router.grouped("api", "users")

        let basicAuth = User.basicAuthMiddleware(using: BCryptDigest())
        
        let basicAuthRoute = usersRoute.grouped(basicAuth)
        basicAuthRoute.post("authenticate", use: authenticate)
        
        // General API calls
        
        usersRoute.post(User.CreateRequest.self, use: create)
        usersRoute.get(User.parameter, use: get)
        usersRoute.patch(User.parameter, use: update)
        usersRoute.get("usernamecheck", use: checkUsernameAvailability)
    }
    
    func authenticate(_ req: Request) throws -> Future<Token> {
        let user = try req.requireAuthenticated(User.self)
        
        let token = try Token.generate(for: user)
        
        return token.save(on: req)
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

    func update(_ req: Request) throws -> Future<User.Public> {
        let masterKey = req.http.headers["X-ShortcutSharing-Master-Key"].first
        let isAuthenticatedAsMaster = (masterKey == self.masterKey)

        let queryKey = try? req.query.get(String.self, at: ["apiKey"])
        let apiKey = req.http.headers["X-Shortcuts-Key"].first ?? queryKey

        var userKey = ""

        if !isAuthenticatedAsMaster {
            guard let apiKey = apiKey else {
                throw Abort(.forbidden)
            }

            userKey = apiKey
        }

        do {
            let fetchUser = try req.parameters.next(User.self)

            return fetchUser.flatMap { user in
                if !isAuthenticatedAsMaster {
                    guard let userApiKey = user.apiKey else {
                        throw Abort(.forbidden)
                    }

                    let authSuccessful = try BCrypt.verify(userKey, created: userApiKey)

                    guard authSuccessful else {
                        throw Abort(.forbidden)
                    }
                }

                if !user.password.isEmpty {
                    let currentPassword = try req.content.syncGet(String.self, at: ["currentPassword"])

                    let existingPasswordMatches = try BCrypt.verify(currentPassword, created: user.password)

                    guard existingPasswordMatches else {
                        throw Abort(.forbidden)
                    }
                }

                let newPassword = try req.content.syncGet(String.self, at: ["password"])
                let passwordConfirmation = try req.content.syncGet(String.self, at: ["passwordConfirmation"])

                guard newPassword == passwordConfirmation else {
                    throw Abort(.badRequest)
                }

                user.password = try BCrypt.hash(newPassword)

                return user.save(on: req).map { $0.publicView }
            }
        } catch {
            throw Abort(.notFound)
        }
    }
    
    func checkUsernameAvailability(_ req: Request) throws -> Future<UsernameAvailabilityResponse> {
        guard let username = req.query[String.self, at: "username"] else {
            throw Abort(.badRequest)
        }
        
        let precheck = username.usernameAvaliability
        
        guard precheck.isAvailable else {
            return req.future(precheck)
        }
        
        return User.query(on: req).filter(\.username, .equal, username).count().map(to: UsernameAvailabilityResponse.self) { count in
            let available = (count == 0)
            let message = available ? "" : "Sorry, that username has already been taken. Choose another one."
            
            return UsernameAvailabilityResponse(
                username: username,
                isAvailable: count == 0,
                message: message
            )
        }
    }

}
