//
//  SemanticError.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 17/10/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation

final class SemanticError : CompilerError {
    let message: String

    required init(message: String, file: StaticString = #file, line: UInt = #line) {
        let filename = file.description.split(separator: "/").last
        print("Debug error: " + message + " in file \(filename ?? "`unknown`") at line \(line)")
        self.message = message
    }

    internal var debugDescriptionPrefix: String { return "Semantic" }
}
