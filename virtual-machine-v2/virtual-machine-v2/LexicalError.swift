//
//  LexicalError.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 18/09/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation

final class LexicalError : Error, CustomStringConvertible, CustomDebugStringConvertible {
    let message: String

    init(message: String) {
        self.message = message
    }

    // MARK: Custom String Convertible Conformance
    var description: String { return message }

    // MARK: Custom Debug String Convertible Conformance
    var debugDescription: String { return "Lexical error: \(message)" }
}

