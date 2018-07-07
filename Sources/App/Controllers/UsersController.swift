//
//  UsersController.swift
//  App
//
//  Created by Guilherme Rambo on 07/07/18.
//

import Foundation
import Vapor
import FluentPostgreSQL

final class UsersController: RouteCollection {

    let masterKey: String

    init(masterKey: String) {
        self.masterKey = masterKey
    }

    func boot(router: Router) throws {
        let usersRoute = router.grouped("api", "users")
        usersRoute.post(User.self, use: create)
        usersRoute.get(User.parameter, use: get)
    }

    func get(_ req: Request) throws -> Future<UserResponse> {
        do {
            let fetchUser = try req.parameters.next(User.self)

            return fetchUser.map(to: UserResponse.self) { user in
                return UserResponse(user)
            }
        } catch {
            throw Abort(.notFound)
        }
    }

    func create(_ req: Request, user: User) throws -> Future<User> {
        guard let masterKey = req.http.headers["X-ShortcutSharing-Master-Key"].first else {
            throw Abort(.forbidden)
        }
        guard masterKey == self.masterKey else {
            throw Abort(.forbidden)
        }

        return user.save(on: req)
    }

}

struct UserResponse: Codable {
    let id: User.ID?
    let name: String
    let username: String
    let url: URL

    init(_ user: User) {
        self.id = user.id
        self.name = user.name
        self.username = user.username
        self.url = user.url
    }
}

extension UserResponse: Content { }
