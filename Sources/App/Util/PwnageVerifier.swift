import Foundation
import Vapor
import Crypto

/*
 By default, this class requires https://github.com/idrougge/sha1-swift to work,
 you can replace the default SHA1 implementation by setting the hash property to a function 
 that takes a String and returns an optional String (the SHA1 hex string of the input)
 */

/// Uses the pwnedpasswords API to verify password integrity
public final class PwnageVerifier {
    
    /// The base URL for the pwnedpasswords service (a default is provided by the initializer)
    let baseURL: URL

    let container: Container
    let logger: Logger
    
    init(container: Container, baseURL: URL = URL(string: "https://api.pwnedpasswords.com/range")!) throws {
        self.container = container
        self.logger = try container.make(Logger.self)
        self.baseURL = baseURL
    }

    /// Errors returned in the verify completion handler
    public enum Failure: Error {
        /// The hashing failed
        case hashing
        /// An HTTP error occurred (includes the error code)
        case http(Int)
        /// A low-level networking error occurred at the URLSession level
        case networking(Error)
        /// Verifier failed to parse the data returned from the service
        case parsing
        
        public var localizedDescription: String {
            switch self {
                case .hashing: return "Failed to hash the input password"
                case .http(let code): return "HTTP error \(code)"
                case .networking(let err): return "Connection failed with error: \(err.localizedDescription)"
                case .parsing: return "Failed to parse results returned from the server"
            }
        }
    }
    
    /// Represents a pwnage verification result
    public enum Result: CustomStringConvertible {
        /// Failed to verify password
        case error(Failure)
        /// The password has been pwned (includes count of times pwned)
        case pwned(Int)
        /// The password has not been pwned
        case safe
        
        public var description: String {
            switch self {
                case .safe: 
                    return "This password has not appeared in any known data breaches"
                case .pwned(let count): 
                    return "This password has appeared in data breaches \(count) times"
                case .error(let failure): 
                    return failure.localizedDescription
            }
        }
    }
    
    private func hashRanges(from password: String) -> (String, String)? {
        guard let hash = try? SHA1.hash(password) else { return nil }
        
        let effectiveHash = hash.hexEncodedString().replacingOccurrences(of: " ", with: "")
        
        let endIndex = effectiveHash.index(effectiveHash.startIndex, offsetBy: 5)
        let k = String(effectiveHash[effectiveHash.startIndex..<endIndex])
        let r = String(effectiveHash[endIndex...])
        
        return (k.uppercased(), r.uppercased())
    }
    
    func verify(password: String) -> Future<Result> {
        let promise: EventLoopPromise<Result> = container.eventLoop.newPromise()
        
        _verify(password: password) { result in
            switch result {
            case .error(let error):
                promise.fail(error: error)
            default:
                promise.succeed(result: result)
            }
        }
        
        return promise.futureResult
    }
    
    /// Performs a pwnage verification for the input password, the completion handler is called on the main queue
    private func _verify(password: String, completion: @escaping (Result) -> Void) {
        guard let (verifyRange, matchRange) = hashRanges(from: password) else {
            completion(.error(.hashing))
            return
        }
        
        let url = baseURL.appendingPathComponent(verifyRange)
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let `self` = self else { return }
            
            var result: Result
            
            defer {
                completion(result)
            }
            
            if let error = error {
                result = .error(.networking(error))
                self.logger.error("Networking error: \(error)")
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                result = .error(.parsing)
                self.logger.error("Not an HTTPURLResponse, weird")
                return
            }
            
            guard response.statusCode == 200 else {
                result = .error(.http(response.statusCode))
                self.logger.error("Error response from server: \(response.statusCode)")
                return
            }
            
            guard let data = data else {
                result = .error(.parsing)
                self.logger.error("Failed to parse response, no data")
                return
            }
            
            guard let contents = String(data: data, encoding: .utf8) else {
                result = .error(.parsing)
                self.logger.error("Failed to parse response")
                return
            }
            
            result = self.process(response: contents, for: matchRange)
        }
        
        task.resume()
    }
    
    private func process(response: String, for hash: String) -> Result {
        let lines = response.components(separatedBy: "\r\n")
        
        if let match = lines.first(where: { $0.contains(hash) }) {
            let components = match.components(separatedBy: ":")
            guard components.count > 1 else { return .error(.parsing) }
            
            return .pwned(Int(components[1]) ?? -1)
        } else {
            return .safe
        }
    }
    
}

extension PwnageVerifier: Service { }

// MARK: - Request Convenience

extension Request {
    
    private static let maxPwnedCount: Int = 50
    
    func checkPwnage(for password: String) throws -> Future<String?> {
        let verifier = try make(PwnageVerifier.self)
        
        let pwnageVerification = verifier.verify(password: password)
        
        return pwnageVerification.map(to: String?.self) { pwnageResult in
            if case .pwned(let count) = pwnageResult, count >= Request.maxPwnedCount {
                let learnMoreLink = "<a href=\"/pwned\" target=\"_blank\">What's this?</a>"
                return "Sorry, this password has been found on \(count) security incidents, you need to choose a secure one. \(learnMoreLink)"
            } else {
                return nil
            }
        }
    }
    
}
