//
//  VotingClient.swift
//  App
//
//  Created by Guilherme Rambo on 06/10/18.
//

import Foundation
import Vapor

final class VotingClient {
    
    enum VotingError: Error {
        case http(Int)
        case serialization
    }
    
    let logger: Logger
    let container: Container
    let baseURL: URL
    
    init(container: Container, baseURL: URL = URL(string: "https://voting.sharecuts.app/")!) throws {
        self.container = container
        self.logger = try container.make(Logger.self)
        self.baseURL = baseURL
    }
    
    func getVotes(for id: UUID) -> Future<VotingResponse> {
        return performVotingRequest(with: id, method: "GET")
    }
    
    func vote(for id: UUID) -> Future<VotingResponse> {
        return performVotingRequest(with: id, method: "PUT")
    }
    
    private func performVotingRequest(with id: UUID, method: String) -> Future<VotingResponse> {
        let promise: EventLoopPromise<VotingResponse> = container.eventLoop.newPromise()
        
        let url = baseURL.appendingPathComponent(id.uuidString)
        
        var request = URLRequest(url: url)
        
        request.httpMethod = method
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let `self` = self else { return }
            
            if let error = error {
                self.logger.error("Failed to vote for \(id): \(error)")
                
                promise.fail(error: error)
                
                return
            }
            
            guard let effectiveResponse = response as? HTTPURLResponse else {
                self.logger.error("Reponse as not an HTTP response")
                
                promise.fail(error: VotingError.http(-1))
                
                return
            }
            
            guard effectiveResponse.statusCode == 200 else {
                self.logger.error("HTTP error when voting for \(id): \(effectiveResponse.statusCode)")
                
                promise.fail(error: VotingError.http(effectiveResponse.statusCode))
                
                return
            }
            
            guard let data = data else {
                self.logger.error("Failed to vote for \(id): no data returned from voting service")
                
                promise.fail(error: VotingError.serialization)
                
                return
            }
            
            do {
                let votingResult = try JSONDecoder().decode(VotingResponse.self, from: data)
                
                promise.succeed(result: votingResult)
            } catch {
                self.logger.error("Error unserializing response from voting service: \(error)")
                
                promise.fail(error: error)
            }
        }
        
        task.resume()
        
        return promise.futureResult
    }
    
}

extension VotingClient: Service { }

struct VotingResponse: Codable {
    let id: UUID
    let rating: Int
}

extension VotingResponse: Content { }
