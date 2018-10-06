//
//  Shortcut+VotingCookie.swift
//  App
//
//  Created by Guilherme Rambo on 06/10/18.
//

import Foundation
import Vapor

extension Shortcut {
    
    func isInVotingCookie(with req: Request) throws -> Bool {
        guard let str = try req.session()["voting"] else { return false }
        
        let ids = str.components(separatedBy: "|")
        
        return try ids.contains(requireID().uuidString)
    }
    
    func addToVotingCookie(with req: Request) throws {
        var str = try req.session()["voting"] ?? ""
        
        let id = try requireID().uuidString
        
        guard !str.contains(id) else { return }
        
        str += "|\(id)"
        
        try req.session()["voting"] = str
    }
    
}
