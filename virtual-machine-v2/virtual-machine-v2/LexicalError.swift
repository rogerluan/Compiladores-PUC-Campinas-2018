//
//  LexicalError.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 18/09/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation

final class LexicalError : CompilerError {
    let message: String
    
    required init(message: String, file: StaticString = #file, line: UInt = #line) {
        let filename = file.description.split(separator: "/").last
        print("Debug error: " + message + " in file \(filename ?? "`unknown`") at line \(line)")
        self.message = message
    }

    internal var debugDescriptionPrefix: String { return "Lexical" }
}

