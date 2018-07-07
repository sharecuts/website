//
//  WebsiteController.swift
//  App
//
//  Created by Guilherme Rambo on 07/07/18.
//

import Foundation

import Foundation
import Vapor
import FluentPostgreSQL
import Leaf

final class WebsiteController: RouteCollection {

    let downloadsBaseURL: URL

    init(downloadsBaseURL: URL) {
        self.downloadsBaseURL = downloadsBaseURL
    }

    func boot(router: Router) throws {
        router.get(use: index)
        router.get("download", Shortcut.parameter, use: download)
        router.get("upload", use: upload)
        router.get("about", use: about)
    }

    func index(_ req: Request) throws -> Future<View> {
        let query = Shortcut.query(on: req).range(0...20).sort(\.createdAt, .descending).all()

        return query.flatMap(to: View.self) { shortcuts in
            let userFutures = shortcuts.map({ $0.user.query(on: req).first() })

            return userFutures.flatMap(to: View.self, on: req) { users in
                let unwrappedUsers = users.compactMap({ $0 })
                let cards = shortcuts.compactMap({ try? ShortcutCard($0, users: unwrappedUsers) })

                return try req.view().render("index", ["cards": cards])
            }
        }
    }

    func download(_ req: Request) throws -> Future<Response> {
        let shortcutQuery = try req.parameters.next(Shortcut.self)

        return shortcutQuery.map(to: Response.self) { shortcut in
            let url = self.downloadsBaseURL.appendingPathComponent(shortcut.filePath)

            let headers = HTTPHeaders([("Location",url.absoluteString)])
            return req.makeResponse(http: HTTPResponse(status: HTTPResponseStatus(statusCode: 302), headers: headers))
        }
    }

    func upload(_ req: Request) throws -> Future<View> {
        let apiKey = try? req.query.get(String.self, at: ["apiKey"])

        let userQuery = User.query(on: req).filter(\.apiKey, .equal, apiKey).first()

        return userQuery.flatMap(to: View.self) { user in
            if (apiKey != nil && apiKey?.isEmpty != true) {
                guard user != nil else {
                    throw Abort(.forbidden)
                }
            }

            return try req.view().render("upload", ["apiKey": apiKey])
        }
    }

    func about(_ req: Request) throws -> Future<View> {
        return try req.view().render("about")
    }

}

struct ShortcutCard: Codable {
    let shortcut: Shortcut
    let creator: User

    init(_ shortcut: Shortcut, users: [User]) throws {
        self.shortcut = shortcut

        guard let user = users.first(where: { $0.id == shortcut.userID }) else {
            throw Abort(.notFound)
        }

        self.creator = user
    }
}

extension ShortcutCard: Content { }
