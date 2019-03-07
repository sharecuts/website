//
//  ShortcutLinkImporter.swift
//  App
//
//  Created by Guilherme Rambo on 07/03/19.
//

import Foundation
import Vapor

fileprivate struct ShortcutImportMetadata: Decodable {
    let downloadURL: URL

    init?(data: Data, identifier: String, logger: Logger? = nil) {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            logger?.error("Failed to parse metadata as JSON")
            return nil
        }

        guard let fields = json?["fields"] as? [String: Any] else {
            logger?.error("Missing fields key in metadata JSON")
            return nil
        }

        guard let shortcutField = fields["shortcut"] as? [String: Any] else {
            logger?.error("Missing fields.shortcut in metadata JSON")
            return nil
        }

        guard let value = shortcutField["value"] as? [String: Any] else {
            logger?.error("Missing fields.shortcut.value in metadata JSON")
            return nil
        }

        guard let urlTemplate = value["downloadURL"] as? String else {
            logger?.error("Missing fields.shortcut.value.downloadURL in metadata JSON")
            return nil
        }

        let urlStr = urlTemplate.replacingOccurrences(of: "${f}", with: identifier)

        guard let url = URL(string: urlStr) else {
            logger?.error("Invalid URL: \(urlStr)")
            return nil
        }

        self.downloadURL = url
    }
}

final class ShortcutLinkImporter {

    let container: Container
    let logger: Logger

    init(container: Container) throws {
        self.container = container
        self.logger = try container.make(Logger.self)
    }

    private struct Constants {
        static let apiBaseURL = URL(string: "https://www.icloud.com/shortcuts/api/records")!
    }

    private struct ImportError: LocalizedError {
        var localizedDescription: String
    }

    private func request(_ url: URL) -> Future<Data> {
        let promise: EventLoopPromise<Data> = container.eventLoop.newPromise()

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                self.logger.error("Shortcut import request failed: \(String(describing: error)). URL \(url).")
                promise.fail(error: error)
                return
            }

            guard let response = response as? HTTPURLResponse else {
                let err = ImportError(localizedDescription: "Invalid response for shortcut import. URL \(url).")
                self.logger.error(err.localizedDescription)
                promise.fail(error: err)
                return
            }

            guard response.statusCode == 200 else {
                let err = ImportError(localizedDescription: "HTTP error \(response.statusCode) when importing shortcut. URL \(url).")
                self.logger.error(err.localizedDescription)
                promise.fail(error: err)
                return
            }

            guard let data = data else {
                let err = ImportError(localizedDescription: "No data returned when importing shortcut. URL \(url).")
                self.logger.error(err.localizedDescription)
                promise.fail(error: err)
                return
            }

            promise.succeed(result: data)
        }

        task.resume()

        return promise.futureResult
    }

    func importShortcut(from url: URL) -> Future<Data> {
        let identifier = url.lastPathComponent

        let metadataURL = Constants.apiBaseURL.appendingPathComponent(identifier)

        return request(metadataURL).flatMap { [unowned self] metadata in
            guard let info = ShortcutImportMetadata(data: metadata, identifier: identifier, logger: self.logger) else {
                let err = ImportError(localizedDescription: "Failed to parse shortcut metadata")
                return self.container.future(error: err)
            }

            return self.request(info.downloadURL)
        }
    }

}

extension ShortcutLinkImporter: Service { }
