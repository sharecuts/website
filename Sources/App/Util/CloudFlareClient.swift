//
//  CloudFlareClient.swift
//  App
//
//  Created by Guilherme Rambo on 08/07/18.
//

import Foundation
import Vapor
import DotEnv

final class CloudFlareClient {

    private static var loggedInitialization = false

    let logger: Logger
    let env: DotEnv

    private var hasValidConfiguration: Bool {
        return email != nil && key != nil && zoneID != nil && url != nil
    }

    private let email: String?
    private let key: String?
    private let zoneID: String?
    private let url: URL?

    init(env: DotEnv, logger: Logger) {
        self.logger = logger
        self.env = env

        guard env.getAsInt("CF_ENABLED") == 1 else {
            logger.info("CloudFlareClient is disabled")
            self.email = nil
            self.key = nil
            self.zoneID = nil
            self.url = nil
            return
        }

        self.email = env["CF_EMAIL"]
        self.key = env["CF_KEY"]
        self.zoneID = env["CF_ZONE_ID"]

        if let urlStr = env["CF_APP_URL"] {
            self.url = URL(string: urlStr)
        } else {
            self.url = nil
        }

        if !CloudFlareClient.loggedInitialization {
            CloudFlareClient.loggedInitialization = true

            if hasValidConfiguration {
                logger.info("CloudFlareClient initialized successfully")
            } else {
                logger.warning(
                    """
                CloudFlareClient will not run because it's not configured properly.
                Make sure CF_EMAIL, CF_KEY, CF_ZONE_ID and CF_APP_URL are present in the environment.
                """
                )
            }
        }
    }

    func purgeCache(at path: String) {
        guard let zoneID = zoneID, let email = email, let key = key, let url = url else { return }

        let urlToPurge = url.appendingPathComponent(path)

        let payload = CloudFlarePurgeRequest(files: [urlToPurge.absoluteString])

        guard let encodedPayload = try? JSONEncoder().encode(payload) else {
            logger.error("Failed to encode payload for cache purge")
            return
        }

        let cfURLStr = "https://api.cloudflare.com/client/v4/zones/\(zoneID)/purge_cache"

        guard let cloudFlareURL = URL(string: cfURLStr) else { return }

        var request = URLRequest(url: cloudFlareURL)
        request.httpMethod = "POST"
        request.addValue(email, forHTTPHeaderField: "X-Auth-Email")
        request.addValue(key, forHTTPHeaderField: "X-Auth-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = encodedPayload

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, res, error in
            guard let `self` = self else { return }

            if let error = error {
                self.logger.error("Failed to purge cache with error: \(String(describing: error))")
                return
            }

            guard let response = res as? HTTPURLResponse else {
                self.logger.error("Received a response which wasn't an HTTP response. WHAT?!")
                return
            }

            if response.statusCode != 200 {
                self.logger.error("Received HTTP error \(response.statusCode) from CloudFlare while trying to purge cache for \(path)")
            }

            guard let data = data else {
                self.logger.error("Received no data from CloudFlare when purging cache for \(path)")
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(CloudFlarePurgeResponse.self, from: data)

                guard decodedResponse.success else {
                    let errors = decodedResponse.errors.joined(separator: "\n")
                    self.logger.info("Received error response from CloudFlare when purging the cache for \(path):\n\(errors)")
                    return
                }

                self.logger.info("Purged cache successfully for \(path)")
            } catch {
                self.logger.error("Failed to decode CloudFlare's response when purging the cache for \(path)")
            }
        }

        task.resume()
    }

}

extension CloudFlareClient: Service { }

fileprivate struct CloudFlarePurgeRequest: Codable {
    let files: [String]
}

fileprivate struct CloudFlarePurgeResponse: Codable {
    let success: Bool
    let errors: [String]
}
