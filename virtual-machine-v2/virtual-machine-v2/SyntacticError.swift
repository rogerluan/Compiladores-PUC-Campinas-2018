//
//  SyntacticError.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 26/09/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation

final class SyntacticError : CompilerError {
    let message: String

    required init(message: String, file: StaticString = #file, line: UInt = #line) {
        let filename = file.description.split(separator: "/").last
        print("Debug error: " + message + " in file \(filename ?? "`unknown`") at line \(line)")
        self.message = message
    }

    convenience init(expected: String, butFound token: Token, file: StaticString = #file, line: UInt = #line) {
        self.init(message: NSLocalizedString("Expected \(expected) but found `\(token.lexeme)` at line \(token.line)", comment: ""), file: file, line: line)
    }

    convenience init(expected: String, butFoundEOF: (), file: StaticString = #file, line: UInt = #line) {
        self.init(message: NSLocalizedString("Expected \(expected) but found end of file.", comment: ""), file: file, line: line)
    }

    internal var debugDescriptionPrefix: String { return "Syntactic" }
}
