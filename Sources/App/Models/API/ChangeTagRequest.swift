//
//  ChangeTagRequest.swift
//  App
//
//  Created by Guilherme Rambo on 06/10/18.
//

import Foundation
import Vapor

struct ChangeTagRequest: Codable {
    let tag: String
}

extension ChangeTagRequest: Content { }
