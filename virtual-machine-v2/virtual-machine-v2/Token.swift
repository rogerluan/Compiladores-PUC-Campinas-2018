//
//  Token.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 18/09/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation

struct Token : CustomDebugStringConvertible {
    /// Enum that contains an internal representation to a token. Comparisons are done using this symbol since it's backed by a UInt raw value, briging being more efficiency to the comparisons.
    let symbol: Symbol
    /// Contains the sequence of characters - letters, numbers, etc. - that compounds the token.
    let lexeme: String
    /// Line of occurrence of this token, in the source code. Used to point to the user which line has problems (errors).
    let line: UInt

    // MARK: Types
    enum Symbol : UInt {
        case s_program = 1
        case s_start
        case s_end
        case s_procedure
        case s_function
        case s_if
        case s_then
        case s_else
        case s_while
        case s_do
        case s_assignment
        case s_write
        case s_read
        case s_var
        case s_integer
        case s_boolean
        case s_identifier
        case s_true
        case s_false
        case s_number
        case s_period
        case s_semicolon
        case s_comma
        case s_left_parenthesis
        case s_right_parenthesis
        case s_greater
        case s_greaterThanOrEqualTo
        case s_equal
        case s_lesser
        case s_lesserThanOrEqualTo
        case s_different
        case s_plus // TODO: Rename to sum?
        case s_minus // TODO: Rename to subtraction?
        case s_multiplication // TODO: Rename to asterisk? Star?
        case s_division // TODO: Rename?
        case s_and
        case s_or
        case s_not
        case s_colon
    }

    // MARK: Custom Debug String Convertible Conformance
    var debugDescription: String { return "Token @ line \(line) | lexeme = \(lexeme) \t | \t symbol = \(symbol)" }
}
