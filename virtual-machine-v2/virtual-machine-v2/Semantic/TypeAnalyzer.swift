//
//  SemanticAnalyzer.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 17/10/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation

final class TypeAnalyzer {
    private var output: [TokenType] = []
    private var operatorStack: [TokenType] = []
    private var debugInputString = ""

    /// The isUnary parameter is required because only the caller (context-aware, i.e. knowner of the grammar of the language) knows whether a plus/minus sign is an unary operator.
    func analyzeTerm(_ term: Token, isUnary: Bool = false) {
        debugInputString += "\(term.lexeme) "
        var op: TokenType? = nil
        switch term.symbol {
        case .s_number: output.append(TokenType.operand(term.lexeme)) // Done
        case .s_identifier: output.append(TokenType.operand(term.lexeme)) // Done
        case .s_true: output.append(TokenType.operand(term.lexeme)) // Done
        case .s_false: output.append(TokenType.operand(term.lexeme)) // Done
        case .s_left_parenthesis: op = .leftParenthesis // Done
        case .s_right_parenthesis: op = .rightParenthesis // Done
        case .s_greater: op = .operator(.greater)
        case .s_greaterThanOrEqualTo: op = .operator(.greaterThanOrEqualTo)
        case .s_equal: op = .operator(.equal)
        case .s_lesser: op = .operator(.lesser)
        case .s_lesserThanOrEqualTo: op = .operator(.lesserThanOrEqualTo)
        case .s_different: op = .operator(.different)
        case .s_plus: op = isUnary ? .operator(.unaryPlus) : .operator(.sum)
        case .s_minus: op = isUnary ? .operator(.unaryMinus) : .operator(.subtraction)
        case .s_multiplication: op = .operator(.multiplication) // Done
        case .s_division: op = .operator(.division) // Done
        case .s_and: op = .operator(.and) // Done
        case .s_or: op = .operator(.or)
        case .s_not: op = .operator(.not) // Done
        case .s_program, .s_start, .s_end, .s_procedure, .s_function, .s_if, .s_then, .s_else, .s_while, .s_do, .s_assignment, .s_write, .s_read, .s_var, .s_integer, .s_boolean, .s_period, .s_semicolon, .s_comma, .s_colon: preconditionFailure("Received unexpected term with lexeme \(term.lexeme)")
        }
        if let op = op {
            switch op {
            case .leftParenthesis:
                // Simply push the left parenthesis
                operatorStack.insert(op, at: 0)
            case .rightParenthesis:
                // Pop until find left parenthesis (and also pop the left parenthesis
                var indicesToDrop: [Int] = []
                outerLoop: for (index, tokenType) in operatorStack.enumerated() {
                    switch tokenType {
                    case .leftParenthesis:
                        indicesToDrop.append(index)
                        break outerLoop
                    case .operand(_), .rightParenthesis: preconditionFailure() // These are never added to the operator stack
                    case .operator(let innerOperator):
                        output.append(.operator(innerOperator))
                        indicesToDrop.append(index) // Don't drop the element here to avoid accessing indices out of bounds
                    }
                }
                // Drop the indices reversed to avoid changing the indices while dropping
                indicesToDrop.reversed().forEach { operatorStack.remove(at: $0) }
            case .`operator`(let outerOperator):
                // Pop until find left parenthesis or an operator that has less precedence than the operator being currently analyzed
                var indicesToDrop: [Int] = []
                outerLoop: for (index, tokenType) in operatorStack.enumerated() {
                    switch tokenType {
                    case .leftParenthesis: break outerLoop
                    case .operand(_), .rightParenthesis: preconditionFailure() // These are never added to the operator stack
                    case .operator(let innerOperator):
                        if innerOperator >= outerOperator {
                            output.append(.operator(innerOperator))
                            indicesToDrop.append(index) // Don't drop the element here to avoid accessing indices out of bounds
                        } else {
                            break outerLoop
                        }
                    }
                }
                // Drop the indices reversed to avoid changing the indices while dropping
                indicesToDrop.reversed().forEach { operatorStack.remove(at: $0) }
                operatorStack.insert(op, at: 0)
            case .operand(_): break // Do nothing
            }
        } else {
            // Do nothing
        }
    }

    func finalize() -> [TokenType] {
        _ = operatorStack.drop { tokenType -> Bool in
            output.append(tokenType)
            return true
        }
        print("Before: " + debugInputString)
        let result = output
        print("After: " + output.reduce("") { $0 + "\($1) " })
        resetAnalyzer()
        return result
    }

    // TODO: Evaluate if this is necessary, as opposed to really creating a new object and initializing it again in the SyntacticAnalyzer file.
    private func resetAnalyzer() {
        operatorStack.removeAll()
        output.removeAll()
        debugInputString = ""
    }

    // MARK: Nested Types
    enum PrecedenceGroup : Int {
        case unary = 200
        case multiplication = 180
        case sum = 160
        case comparison = 140
        case and = 120
        case or = 100
    }

    enum Operator : CustomStringConvertible, Comparable {
        static func < (lhs: Operator, rhs: Operator) -> Bool {
            return lhs.precedence.rawValue < rhs.precedence.rawValue
        }

        case unaryPlus, unaryMinus, not
        case multiplication, division
        case sum, subtraction
        case greater, lesser, greaterThanOrEqualTo, lesserThanOrEqualTo, equal, different
        case and
        case or

        var precedence: PrecedenceGroup {
            switch self {
            case .unaryPlus, .unaryMinus, .not: return .unary
            case .multiplication, .division: return .multiplication
            case .sum, .subtraction: return .sum
            case .greater, .lesser, .greaterThanOrEqualTo, .lesserThanOrEqualTo, .equal, .different: return .comparison
            case .and: return .and
            case .or: return .or
            }
        }

        var description: String {
            switch self {
            case .unaryPlus: return " u+"
            case .unaryMinus: return " u-"
            case .not: return " !"
            case .multiplication: return " * "
            case .division: return " / "
            case .sum: return " + "
            case .subtraction: return " - "
            case .greater: return " > "
            case .lesser: return " < "
            case .greaterThanOrEqualTo: return " >= "
            case .lesserThanOrEqualTo: return " <= "
            case .equal: return " == "
            case .different: return " != "
            case .and: return " && "
            case .or: return " | "
            }
        }
    }

    enum TokenType : CustomStringConvertible {
        case leftParenthesis
        case rightParenthesis
        case `operator`(Operator)
        case operand(String) // FIXME: Use something better to identify the operand, like the Token itself

        var description: String {
            switch self {
            case .leftParenthesis: return "("
            case .rightParenthesis: return ")"
            case .operator(let op): return op.description
            case .operand(let value): return "\(value)"
            }
        }
    }
}
