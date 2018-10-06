//
//  JobScheduler.swift
//  App
//
//  Created by Guilherme Rambo on 06/10/18.
//

import Foundation
import Vapor

final class JobScheduleManager {
    
    fileprivate static var shared: JobScheduleManager!
    
    fileprivate let container: Container
    fileprivate let logger: Logger
    
    fileprivate init(container: Container) throws {
        self.container = container
        self.logger = try container.make(Logger.self)
        
        run()
    }
    
    static func initialize(with container: Container) throws {
        JobScheduleManager.shared = try JobScheduleManager(container: container)
    }
    
    private var scheduledJobs: [ScheduledJob] = [] {
        didSet {
            run()
        }
    }
    
    fileprivate func schedule(job: ScheduledJob) {
        scheduledJobs = scheduledJobs + [job]
    }
    
    fileprivate func run() {
        scheduledJobs.filter({ !$0.isRunning }).forEach { job in
            logger.info("Scheduling job \(job.name) every \(job.interval) seconds")

            job.start(in: container, logger: logger)
        }
    }
    
}

class ScheduledJob {
    
    let id: UUID
    let name: String
    var interval: TimeInterval
    var work: (Container) throws -> Void
    
    init(name: String = "", interval: TimeInterval, work: @escaping (Container) throws -> Void) {
        self.id = UUID()
        self.name = name
        self.interval = interval
        self.work = work
    }
    
    private lazy var queue: DispatchQueue = {
        return DispatchQueue(label: name, qos: .background)
    }()
    
    fileprivate var isRunning = false
    
    fileprivate func start(in container: Container, logger: Logger) {
        guard !isRunning else { return }

        queue.async {
            do {
                try self.work(container)
            } catch {
                logger.error("Scheduled job \(self.name) failed: \(error)")
            }
            
            Thread.sleep(forTimeInterval: self.interval)
        }
    }
    
}

final class JobScheduler {
    
    func schedule(job: ScheduledJob) {
        JobScheduleManager.shared.schedule(job: job)
    }
    
}

extension JobScheduler: Service { }
