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

    required init(message: String) {
        self.message = message
    }

    convenience init(expected: String, butFound token: Token) {
        self.init(message: NSLocalizedString("Expected \(expected) but found `\(token.lexeme)` at line \(token.line)", comment: ""))
    }

    convenience init(expected: String, butFoundEOF: ()) {
        self.init(message: NSLocalizedString("Expected \(expected) but found end of file.", comment: ""))
    }

    internal var debugDescriptionPrefix: String { return "Syntactic" }
}
