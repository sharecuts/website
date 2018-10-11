//
//  String+Username.swift
//  App
//
//  Created by Guilherme Rambo on 11/10/18.
//

import Foundation

extension String {
    
    private static let reservedUsernames: [String] = [
        "_inside",
        "insidegui",
        "guirambo",
        "rambo",
        "rambo.codes",
        "guilhermerambo",
        "sharecuts",
        "sharecuts.app",
        "sharecuts_app",
        "sharecutsapp",
        "shortcuts",
        "siri",
        "apple",
        "iphone",
        "ipad",
        "ipod"
    ]
    
    static let usernameRulesExplanation = "Username must start with a letter, can only contain numbers, lowercase letters, dashes, underscores and dots."
    
    private static let usernameStartProhibitedCharacters = "0123456789-_."
    private static let usernameAllowedCharacters = CharacterSet(charactersIn: "0123456789abcdefghijklmnopqrstuvwxyz-_.")
    
    var isReserved: Bool {
        return String.reservedUsernames.contains(self.lowercased())
    }
    
    var isValidUsername: Bool {
        guard self.count >= 3 else { return false }
        
        if String.usernameStartProhibitedCharacters.contains(self[startIndex]) {
            return false
        }
        
        return self == trimmingCharacters(in: String.usernameAllowedCharacters.inverted)
    }
    
    var usernameAvaliability: UsernameAvailabilityResponse {
        guard count >= 3 else {
            return UsernameAvailabilityResponse(username: self, isAvailable: false, message: "Username must be at least 3 characters long.")
        }
        
        guard count <= 20 else {
            return UsernameAvailabilityResponse(username: self, isAvailable: false, message: "The maximum length of the username is 20 characters.")
        }
        
        guard !isReserved else {
            return UsernameAvailabilityResponse(username: self, isAvailable: false, message: "That username can't be used, please choose another one.")
        }
        
        guard isValidUsername else {
            return UsernameAvailabilityResponse(username: self, isAvailable: false, message: String.usernameRulesExplanation)
        }
    
        return UsernameAvailabilityResponse(username: self, isAvailable: true, message: "")
    }
    
}
