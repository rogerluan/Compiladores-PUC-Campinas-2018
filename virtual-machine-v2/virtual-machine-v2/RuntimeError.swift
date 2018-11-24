//
//  RuntimeError.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 21/11/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation

final class RuntimeError : Error {
    let message: String
    var title: String = NSLocalizedString("Runtime Error", comment: "")

    required init(message: String, file: StaticString = #file, line: UInt = #line) {
        let filename = file.description.split(separator: "/").last
        print("Debug error: " + message + " in file \(filename ?? "`unknown`") at line \(line)")
        self.message = message
    }
}

extension RuntimeError : CustomStringConvertible {
    var description: String { return message }
}

extension RuntimeError : CustomDebugStringConvertible {
    var debugDescription: String { return String(format: NSLocalizedString("Runtime error: %@", comment: ""), message) }
}
