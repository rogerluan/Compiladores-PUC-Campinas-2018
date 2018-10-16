//
//  CompilerError.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 03/10/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation

protocol CompilerError : Error, CustomStringConvertible, CustomDebugStringConvertible {
    var message: String { get }
    var title: String { get }
    var debugDescriptionPrefix: String { get }

    init(message: String)
}

extension CompilerError {
    var title: String { return "\(debugDescriptionPrefix) Error" }
}

extension CompilerError {
    var description: String { return message }
}

extension CompilerError {
    var debugDescription: String { return "\(debugDescriptionPrefix) error: \(message)" }
}
