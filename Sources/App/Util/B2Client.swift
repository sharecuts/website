//
//  B2Client.swift
//  App
//
//  Created by Guilherme Rambo on 07/07/18.
//

import Foundation
import Vapor

final class B2Client {

    var config: B2Config?

    static let shared: B2Client = B2Client()

    private lazy var queue = DispatchQueue(label: "B2Uploader")

    enum B2Error: Error {
        case notConfigured
        case invalidResponseFromB2
        case generic(String)
        case dataConversion
    }

    private lazy var temporaryStorageURL: URL = {
        return URL(fileURLWithPath: NSTemporaryDirectory())
    }()

    private func writeTemporaryFile(_ file: File) throws -> URL {
        let originURL = URL(fileURLWithPath: "/"+file.filename)
        let sanitizedName = originURL.deletingPathExtension().lastPathComponent.slugified + "." + originURL.pathExtension

        let url = temporaryStorageURL.appendingPathComponent(sanitizedName)

        let finalPath = url.deletingPathExtension().path + UUID().uuidString + "." + originURL.pathExtension
        let finalURL = URL(fileURLWithPath: finalPath)
        try file.data.write(to: finalURL)

        return finalURL
    }

    func delete(on req: Request, shortcut: Shortcut) -> Future<B2DeleteResult> {
        let promise: EventLoopPromise<B2DeleteResult> = req.eventLoop.newPromise()

        queue.async { [weak self] in
            guard let `self` = self else { return }

            guard let config = self.config else {
                promise.fail(error: B2Error.notConfigured)
                return
            }

            do {
                let logger = try req.make(Logger.self)

                let process = Process()

                var env = process.environment ?? [:]
                env["B2_ACCOUNT_INFO"] = config.infoPath
                process.environment = env

                logger.info("B2 environment:\n\(String(describing: env))")

                process.launchPath = config.executablePath
                process.arguments = [
                    "delete-file-version",
                    shortcut.filePath,
                    shortcut.fileID
                ]

                let err = Pipe()
                process.standardError = err

                let output = Pipe()
                process.standardOutput = output

                process.launch()
                process.waitUntilExit()

                let error = err.fileHandleForReading.readDataToEndOfFile()

                if !error.isEmpty {
                    guard let errorStr = String(data: error, encoding: .utf8) else {
                        throw B2Error.invalidResponseFromB2
                    }

                    logger.error("Failed to delete from B2:\n\(errorStr)")

                    throw B2Error.generic(errorStr)
                }

                let result = output.fileHandleForReading.readDataToEndOfFile()

                let decoder = JSONDecoder()
                let decodedResult = try decoder.decode(B2DeleteResult.self, from: result)

                promise.succeed(result: decodedResult)
            } catch {
                promise.fail(error: error)
            }
        }

        return promise.futureResult
    }

    func upload(on req: Request, file: File, info: ShortcutFile) -> Future<B2UploadResult> {
        let promise: EventLoopPromise<B2UploadResult> = req.eventLoop.newPromise()

        queue.async { [weak self] in
            guard let `self` = self else { return }

            guard let config = self.config else {
                promise.fail(error: B2Error.notConfigured)
                return
            }

            do {
                let logger = try req.make(Logger.self)

                let tempURL = try self.writeTemporaryFile(file)

                let process = Process()

                process.launchPath = config.executablePath
                process.arguments = [
                    "upload-file",
                    "--noProgress",
                    config.bucketName,
                    tempURL.path,
                    tempURL.lastPathComponent
                ]

                let err = Pipe()
                process.standardError = err

                let output = Pipe()
                process.standardOutput = output

                process.launch()
                process.waitUntilExit()

                let error = err.fileHandleForReading.readDataToEndOfFile()

                if !error.isEmpty {
                    guard let errorStr = String(data: error, encoding: .utf8) else {
                        throw B2Error.invalidResponseFromB2
                    }

                    logger.error("B2 bucket error: " + errorStr)

                    throw B2Error.generic(errorStr)
                }

                let result = output.fileHandleForReading.readDataToEndOfFile()

                guard let resultStr = String(data: result, encoding: .utf8) else {
                    logger.error("Failed to decode B2 result string as utf8")

                    throw B2Error.invalidResponseFromB2
                }

                let lines = resultStr.components(separatedBy: "\n")
                guard lines.count > 2 else {
                    logger.error("Result string from B2 was too short")

                    throw B2Error.invalidResponseFromB2
                }

                let sanitizedResponse = lines[2...].joined()
                guard let sanitizedData = sanitizedResponse.data(using: .utf8) else {
                    logger.error("Failed to encode sanitized B2 result as utf8")

                    throw B2Error.dataConversion
                }

                let decoder = JSONDecoder()
                let decodedResult = try decoder.decode(B2UploadResult.self, from: sanitizedData)

                do {
                    try FileManager.default.removeItem(at: tempURL)
                } catch {
                    logger.warning("Failed to delete temporary file from \(tempURL.path):\n\(String(describing: error))")
                }

                promise.succeed(result: decodedResult)
            } catch {
                promise.fail(error: error)
            }
        }

        return promise.futureResult
    }

    func fetchFileData(from url: URL, on req: Request) -> Future<Data?> {
        let promise: EventLoopPromise<Data?> = req.eventLoop.newPromise()

        URLSession.shared.dataTask(with: url, completionHandler: { data, _, error in
            if let error = error {
                promise.fail(error: error)
                return
            }

            promise.succeed(result: data)
        }).resume()

        return promise.futureResult
    }

}

struct B2UploadResult: Codable {
    let action: String
    let fileId: String
    let fileName: String
    let size: Int
    let uploadTimestamp: Int
}

struct B2DeleteResult: Codable {
    let action: String
    let fileId: String
    let fileName: String
}
