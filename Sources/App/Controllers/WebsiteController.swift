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
        router.get("download", String.parameter, use: download)
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

    private static let forceWorkflowExtension = false

    func download(_ req: Request) throws -> Future<Response> {
        let identifier = req.http.url.deletingPathExtension().lastPathComponent

        guard let id = UUID(uuidString: identifier) else {
            throw Abort(.badRequest)
        }

        let shortcutQuery = Shortcut.find(id, on: req)

        return shortcutQuery.flatMap(to: Response.self) { shortcut in
            guard let shortcut = shortcut else {
                throw Abort(.notFound)
            }

            let url = self.downloadsBaseURL.appendingPathComponent(shortcut.filePath)

            let download = B2Client.shared.fetchFileData(from: url, on: req)

            return download.map(to: Response.self) { data in
                guard let data = data else {
                    throw Abort(.notFound)
                }

                let ext = WebsiteController.forceWorkflowExtension ? "wflow" : "shortcut"

                let disposition = "attachment; filename=\"\(shortcut.title).\(ext)\""

                let status = HTTPResponseStatus(statusCode: 200)
                let headers = HTTPHeaders([
                    ("Content-Type","application/octet-stream"),
                    ("Content-Length", String(data.count)),
                    ("Content-Disposition", disposition)
                ])

                return req.makeResponse(http: HTTPResponse(status: status, headers: headers, body: data))
            }
        }
    }

    func upload(_ req: Request) throws -> Future<View> {
        let apiKey = try? req.query.get(String.self, at: ["apiKey"])

        let userQuery = User.query(on: req).filter(\.apiKey, .equal, apiKey).first()

        return userQuery.flatMap(to: View.self) { user in
            var context: UploadPageContext

            if (apiKey != nil && apiKey?.isEmpty != true) {
                guard let user = user else {
                    throw Abort(.forbidden)
                }

                context = UploadPageContext(user)
            } else {
                context = UploadPageContext(nil)
            }

            return try req.view().render("upload", context)
        }
    }

    func about(_ req: Request) throws -> Future<View> {
        return try req.view().render("about")
    }

}

struct ShortcutCard: Codable {
    let shortcut: Shortcut
    let creator: User
    let deepLink: String

    init(_ shortcut: Shortcut, users: [User]) throws {
        self.shortcut = shortcut

        guard let user = users.first(where: { $0.id == shortcut.userID }) else {
            throw Abort(.notFound)
        }

        self.creator = user

        self.deepLink = try shortcut.generateDownloadURL().absoluteString
    }
}

extension ShortcutCard: Content { }

struct UploadPageContext: Codable {
    let user: User?
    let firstName: String?

    init(_ user: User?) {
        self.user = user
        self.firstName = user?.firstName
    }
}
