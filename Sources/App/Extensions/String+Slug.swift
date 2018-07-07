//
//  String+Slug.swift
//  App
//
//  Created by Guilherme Rambo on 07/07/18.
//

import Foundation

extension String {
    private static let slugSafeCharacters = CharacterSet(charactersIn: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-")

    // Obtained from: https://github.com/twostraws/SwiftSlug/blob/master/Sources/SwiftSlug.swift
    private func convertedToSlugBackCompat() -> String? {
        // On Linux StringTransform doesn't exist and CFStringTransform causes all sorts
        // of problems because of bridging issues using CFMutableString – d'oh.
        // So we're going to do the only thing possible: dump to ASCII and hope for the best
        if let data = self.data(using: .ascii, allowLossyConversion: true) {
            if let str = String(data: data, encoding: .ascii) {
                let urlComponents = str.lowercased().components(separatedBy: String.slugSafeCharacters.inverted)
                return urlComponents.filter { $0 != "" }.joined(separator: "-")
            }
        }

        // still here? Something went disastrously wrong!
        return nil
    }

    internal var slugified: String {
        guard let result = convertedToSlugBackCompat() else {
            fatalError("convertedToSlugBackCompat failed catastrophically")
        }
        
        return result
    }
}
