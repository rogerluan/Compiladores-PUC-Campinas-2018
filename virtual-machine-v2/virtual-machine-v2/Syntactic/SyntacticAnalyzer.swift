//
//  SyntacticAnalyzer.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 26/09/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation

final class SyntacticAnalyzer {
    private var token: Token?
    private let lexicalAnalyzer: LexicalAnalyzer


    /// Initializes a new instance of
    ///
    /// - Parameter lexicalAnalyzer: A recently initialized lexical analyzer, i.e. one that hasn't read any tokens.
    init?(lexicalAnalyzer: LexicalAnalyzer) {
        self.lexicalAnalyzer = lexicalAnalyzer
    }

    /// Analyzes a `<programa>` structure defined in the formal language grammar.
    func analyzeProgram() throws {
        try readNextTokenIfPossible()
        if let token = self.token {
            guard token.symbol == .s_program else { throw SyntacticError(expected: "`programa`", butFound: token) }
            try readNextTokenIfPossible()
            if let token = self.token {
                guard token.symbol == .s_identifier else { throw SyntacticError(expected: "a program identifier", butFound: token) }
                try readNextTokenIfPossible()
                if let token = self.token {
                    guard token.symbol == .s_semicolon else { throw SyntacticError(expected: "`;`", butFound: token) }
                    try analyzeBlock() // This already reads the next token
                    if let token = self.token {
                        guard token.symbol == .s_period else { throw SyntacticError(expected: "`.`", butFound: token) }
                        if let token = try lexicalAnalyzer.readNextToken() {
                            throw SyntacticError(expected: "end of file", butFound: token)
                        } else {
                            return // Success
                        }
                    } else {
                        throw SyntacticError(expected: "`.`", butFoundEOF: ())
                    }
                } else {
                    throw SyntacticError(expected: "`;`", butFoundEOF: ())
                }
            } else {
                throw SyntacticError(expected: "a program identifier", butFoundEOF: ())
            }
        } else {
            throw SyntacticError(expected: "`programa`", butFoundEOF: ())
        }
    }

    /// Analyzes a `<bloco>` structure defined in the formal language grammar.
    private func analyzeBlock() throws {
        try readNextTokenIfPossible()
        try analyzeVariableDeclarations()
        try analyzeSubroutinesDeclarations()
        try analyzeCommands()
    }

    /// Analyzes a `<etapa de declaração de variáveis>` structure defined in the formal language grammar.
    private func analyzeVariableDeclarations() throws {
        if let token = self.token, token.symbol == .s_var {
            try readNextTokenIfPossible()
            if let token = self.token {
                guard token.symbol == .s_identifier else { throw SyntacticError(expected: "an identifier", butFound: token) }
                while let token = self.token, token.symbol == .s_identifier {
                    try analyzeVariables()
                    if let token = self.token {
                        guard token.symbol == .s_semicolon else { throw SyntacticError(expected: "`;`", butFound: token) }
                        try readNextTokenIfPossible()
                    } else {
                        throw SyntacticError(expected: "`;`", butFoundEOF: ())
                    }
                }
            } else {
                throw SyntacticError(expected: "an identifier", butFoundEOF: ())
            }
        }
    }

    /// Analyzes a `<declaração de variáveis>` structure defined in the formal language grammar.
    private func analyzeVariables() throws {
        repeat {
            if let token = self.token {
                guard token.symbol == .s_identifier else { throw SyntacticError(expected: "an identifier", butFound: token) }
                try readNextTokenIfPossible()
                if let token = self.token {
                    guard token.symbol == .s_comma || token.symbol == .s_colon else { throw SyntacticError(expected: "`,` or `:`", butFound: token) }
                    if token.symbol == .s_comma {
                        try readNextTokenIfPossible()
                        if self.token?.symbol == .s_colon {
                            throw SyntacticError(expected: "an identifier", butFound: self.token!)
                        }
                    } else {
                        // Do nothing
                    }
                } else {
                    throw SyntacticError(expected: "`,` or `:`", butFoundEOF: ())
                }
            } else {
                throw SyntacticError(expected: "an identifier", butFoundEOF: ())
            }
        } while self.token?.symbol != .s_colon
        try readNextTokenIfPossible()
        try analyzeType()
    }

    /// Analyzes a `<tipo>` structure defined in the formal language grammar.
    private func analyzeType() throws {
        if let token = self.token {
            guard token.symbol == .s_integer || token.symbol == .s_boolean else { throw SyntacticError(expected: "`inteiro` or `booleano`", butFound: token) }
            try readNextTokenIfPossible()
        } else {
            throw SyntacticError(expected: "`inteiro` or `booleano`", butFoundEOF: ())
        }
    }

    /// Analyzes a `<etapa de declaração de sub-rotinas>` structure defined in the formal language grammar.
    private func analyzeSubroutinesDeclarations() throws {
//        var flag = false
        if token?.symbol == .s_procedure || token?.symbol == .s_function {
            // TODO: Not implemented yet.
        }
        while token?.symbol == .s_procedure || token?.symbol == .s_function {
            if token?.symbol == .s_procedure {
                try analyzeProcedureDeclaration()
            } else {
                try analyzeFunctionDeclaration()
            }
            if let token = self.token {
                guard token.symbol == .s_semicolon else { throw SyntacticError(expected: "`;`", butFound: token) }
                try readNextTokenIfPossible()
            } else {
                throw SyntacticError(expected: "`;`", butFoundEOF: ())
            }
        }
//        if flag {
            // TODO: Not implemented yet.
//        }
    }

    /// Analyzes a `<declaração de procedimento>` structure defined in the formal language grammar.
    private func analyzeProcedureDeclaration() throws {
        try readNextTokenIfPossible()
        if let token = self.token {
            guard token.symbol == .s_identifier else { throw SyntacticError(expected: "a procedure identifier", butFound: token) }
            try readNextTokenIfPossible()
            if let token = self.token {
                guard token.symbol == .s_semicolon else { throw SyntacticError(expected: "`;`", butFound: token) }
                try analyzeBlock()
            } else {
                throw SyntacticError(expected: "`;`", butFoundEOF: ())
            }
        } else {
            throw SyntacticError(expected: "a procedure identifier", butFoundEOF: ())
        }
    }

    /// Analyzes a `<declaração de função>` structure defined in the formal language grammar.
    private func analyzeFunctionDeclaration() throws {
        try readNextTokenIfPossible()
        if let token = self.token {
            guard token.symbol == .s_identifier else { throw SyntacticError(expected: "a function identifier", butFound: token) }
            try readNextTokenIfPossible()
            if let token = self.token {
                guard token.symbol == .s_colon else { throw SyntacticError(expected: "`:`", butFound: token) }
                try readNextTokenIfPossible()
                if let token = self.token {
                    guard token.symbol == .s_integer || token.symbol == .s_boolean else { throw SyntacticError(expected: "`inteiro` or `booleano`", butFound: token) }
                    try readNextTokenIfPossible()
                    if self.token?.symbol == .s_semicolon {
                        try analyzeBlock()
                    } else {
                        // Do nothing
                    }
                } else {
                    throw SyntacticError(expected: "`inteiro` or `booleano`", butFoundEOF: ())
                }
            } else {
                throw SyntacticError(expected: "`:`", butFoundEOF: ())
            }
        } else {
            throw SyntacticError(expected: "a function identifier", butFoundEOF: ())
        }
    }

    /// Analyzes a `<comandos>` structure defined in the formal language grammar.
    private func analyzeCommands() throws {
        if let token = self.token {
            guard token.symbol == .s_start else { throw SyntacticError(expected: "`inicio`", butFound: token) }
            try readNextTokenIfPossible()
            try analyzeSimpleCommand()
            while let token = self.token, token.symbol != .s_end {
                guard token.symbol == .s_semicolon else { throw SyntacticError(expected: "`;`", butFound: token) }
                try readNextTokenIfPossible()
                if self.token?.symbol != .s_end {
                    try analyzeSimpleCommand()
                } else {
                    // Do nothing
                }
            }
            try readNextTokenIfPossible()
        } else {
            throw SyntacticError(expected: "`inicio`", butFoundEOF: ())
        }
    }

    /// Analyzes a `<comando>` structure defined in the formal language grammar.
    private func analyzeSimpleCommand() throws {
        if token?.symbol == .s_identifier {
            try analyzeAssignmentOrProcedureCall()
        } else if token?.symbol == .s_if {
            try analyzeIf()
        } else if token?.symbol == .s_while {
            try analyzeWhile()
        } else if token?.symbol == .s_read {
            try analyzeRead()
        } else if token?.symbol == .s_write {
            try analyzeWrite()
        } else {
            try analyzeCommands()
        }
    }

    /// Analyzes a `<atribuição_chprocedimento>` structure defined in the formal language grammar.
    private func analyzeAssignmentOrProcedureCall() throws {
        try readNextTokenIfPossible()
        if token?.symbol == .s_assignment {
            try analyzeAssignment()
        } else {
            try analyzeProcedureCall()
        }
    }

    /// Analyzes a `<comando atribuicao>` structure defined in the formal language grammar.
    private func analyzeAssignment() throws {
        try readNextTokenIfPossible()
        try analyzeExpression()
    }

    /// Analyzes a `<chamada de procedimento>` structure defined in the formal language grammar.
    private func analyzeProcedureCall() throws {
        // Not implemented yet
    }

    /// Analyzes a `<chamada de função>` structure defined in the formal language grammar.
    private func analyzeFunctionCall() throws {
        try readNextTokenIfPossible()
    }

    /// Analyzes a `<comando condicional>` structure defined in the formal language grammar.
    private func analyzeIf() throws {
        try readNextTokenIfPossible()
        try analyzeExpression()
        if let token = self.token {
            guard token.symbol == .s_then else { throw SyntacticError(expected: "`entao`", butFound: token) }
            try readNextTokenIfPossible()
            try analyzeSimpleCommand()
            if self.token?.symbol == .s_else {
                try readNextTokenIfPossible()
                try analyzeSimpleCommand()
            } else {
                // Do nothing
            }
        } else {
            throw SyntacticError(expected: "`entao`", butFoundEOF: ())
        }
    }

    /// Analyzes a `<expressão>` structure defined in the formal language grammar.
    private func analyzeExpression() throws {
        try analyzeSimpleExpression()
        switch token?.symbol {
        case .s_greater?, .s_greaterThanOrEqualTo?, .s_equal?, .s_lesser?, .s_lesserThanOrEqualTo?, .s_different?:
            try readNextTokenIfPossible()
            try analyzeSimpleExpression()
        default: break // Do nothing
        }
    }

    /// Analyzes a `<expressão simples>` structure defined in the formal language grammar.
    private func analyzeSimpleExpression() throws {
        if token?.symbol == .s_plus || token?.symbol == .s_minus {
            try readNextTokenIfPossible()
        } else {
            // Do nothing
        }
        try analyzeTerm()
        while token?.symbol == .s_plus || token?.symbol == .s_minus || token?.symbol == .s_or {
            try readNextTokenIfPossible()
            try analyzeTerm()
        }
    }

    /// Analyzes a `<termo>` structure defined in the formal language grammar.
    private func analyzeTerm() throws {
        try analyzeFactor()
        while token?.symbol == .s_multiplication || token?.symbol == .s_division || token?.symbol == .s_and {
            try readNextTokenIfPossible()
            try analyzeFactor()
        }
    }

    /// Analyzes a `<fator>` structure defined in the formal language grammar.
    private func analyzeFactor() throws {
        if token?.symbol == .s_identifier {
            // Must be a variable or a function
            try analyzeFunctionCall()
        } else if token?.symbol == .s_number {
            try readNextTokenIfPossible()
        } else if token?.symbol == .s_not {
            try readNextTokenIfPossible()
            try analyzeFactor()
        } else if token?.symbol == .s_left_parenthesis {
            // Expression between parenthesis
            try readNextTokenIfPossible()
            try analyzeExpression()
            if let token = self.token {
                guard token.symbol == .s_right_parenthesis else { throw SyntacticError(expected: "`)`", butFound: token) }
                try readNextTokenIfPossible()
            } else {
                throw SyntacticError(expected: "`)`", butFoundEOF: ())
            }
        } else if token?.symbol == .s_true || token?.symbol == .s_false {
            try readNextTokenIfPossible()
        } else {
            if let token = token {
                throw SyntacticError(expected: "an identifier, or a number, or `nao`, or `(`, or `true` or `false`", butFound: token)
            } else {
                throw SyntacticError(expected: "`)`", butFoundEOF: ())
            }
        }
    }

    /// Analyzes a `<comando repetição>` structure defined in the formal language grammar.
    private func analyzeWhile() throws {
        try readNextTokenIfPossible()
        try analyzeExpression()
        if let token = self.token {
            guard token.symbol == .s_do else { throw SyntacticError(expected: "`faca`", butFound: token) }
            try readNextTokenIfPossible()
            try analyzeSimpleCommand()
        } else {
            throw SyntacticError(expected: "`faca`", butFoundEOF: ())
        }
    }

    /// Analyzes a `<comando leitura>` structure defined in the formal language grammar.
    private func analyzeRead() throws {
        try readNextTokenIfPossible()
        if let token = self.token {
            guard token.symbol == .s_left_parenthesis else { throw SyntacticError(expected: "`(`", butFound: token) }
            try readNextTokenIfPossible()
            if let token = self.token {
                guard token.symbol == .s_identifier else { throw SyntacticError(expected: "an identifier", butFound: token) }
                try readNextTokenIfPossible()
                if let token = self.token {
                    guard token.symbol == .s_right_parenthesis else { throw SyntacticError(expected: "`)`", butFound: token) }
                    try readNextTokenIfPossible()
                } else {
                    throw SyntacticError(expected: "`)`", butFoundEOF: ())
                }
            } else {
                throw SyntacticError(expected: "an identifier", butFoundEOF: ())
            }
        } else {
            throw SyntacticError(expected: "`(`", butFoundEOF: ())
        }
    }

    /// Analyzes a `<comando escrita>` structure defined in the formal language grammar.
    private func analyzeWrite() throws {
        try readNextTokenIfPossible()
        if let token = self.token {
            guard token.symbol == .s_left_parenthesis else { throw SyntacticError(expected: "`(`", butFound: token) }
            try readNextTokenIfPossible()
            if let token = self.token {
                guard token.symbol == .s_identifier else { throw SyntacticError(expected: "an identifier", butFound: token) }
                try readNextTokenIfPossible()
                if let token = self.token {
                    guard token.symbol == .s_right_parenthesis else { throw SyntacticError(expected: "`)`", butFound: token) }
                    try readNextTokenIfPossible()
                } else {
                    throw SyntacticError(expected: "`)`", butFoundEOF: ())
                }
            } else {
                throw SyntacticError(expected: "an identifier", butFoundEOF: ())
            }
        } else {
            throw SyntacticError(expected: "`(`", butFoundEOF: ())
        }
    }

    // MARK: Utilities
    /// Request the next token from the lexical analyzer, which can throw or return nil if it reached EOF.
    /// If this call throws, the exception is rethrown.
    private func readNextTokenIfPossible() throws {
        token = try lexicalAnalyzer.readNextToken()
    }
}
