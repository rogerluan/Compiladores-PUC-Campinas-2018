//
//  TokenType.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 23/11/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation

enum TokenType : CustomStringConvertible {
    case leftParenthesis
    case rightParenthesis
    case `operator`(Operator)
    case operand(Token)

    var description: String {
        switch self {
        case .leftParenthesis: return "("
        case .rightParenthesis: return ")"
        case .operator(let op): return op.description
        case .operand(let value): return "\(value)"
        }
    }
}
