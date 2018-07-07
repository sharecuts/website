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

    func boot(router: Router) throws {
        router.get(use: index)
    }

    func index(_ req: Request) throws -> Future<View> {
        return try req.view().render("index")
    }

}
