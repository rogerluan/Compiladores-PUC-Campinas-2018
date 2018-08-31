//
//  Throttler.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 29/08/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation

final class Throttler {
    private var task: DispatchWorkItem = DispatchWorkItem(block: {})
    private var lastTaskExecution: Date = Date.distantPast

    /// Minimum TimeInterval between executions, default is 0.1 seconds
    let minInterval: TimeInterval

    /// The queue where the handler block will be called, defaults to the Main Queue
    let queue: DispatchQueue

    init(minInterval: TimeInterval = 0.1, queue: DispatchQueue = .main) {
        self.minInterval = minInterval
        self.queue = queue
    }

    /// Executes the block if the last execution time was at a time longer than the `interval`. If not, schedules its execution
    /// Subsquent calls to this method cancel the last one if there was one scheduled (i.e. 3 consecutive calls will only execute the handler block once)
    ///
    /// - Parameter block: block to be executed
    func throttle(block: @escaping () -> ()) {
        task.cancel()
        task = DispatchWorkItem { [weak self] in
            self?.lastTaskExecution = Date()
            block()
        }
        let delay = Date().timeIntervalSince(lastTaskExecution) > minInterval ? 0 : minInterval
        queue.asyncAfter(deadline: .now() + delay, execute: task)
    }

    /// Cancels any pending job
    func cancel() { task.cancel() }
}
