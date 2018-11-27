//
//  SyntacticAnalyzer.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 26/09/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation

// TODO: Localize all strings
final class SyntacticAnalyzer {
    /// Current token.
    private var token: Token?
    /// The lexical analyzer being used to fetch tokens.
    private let lexicalAnalyzer: LexicalAnalyzer
    /// The type analyzer used to analyze the type of expressions.
    private let typeAnalyzer = TypeAnalyzer()
    /// Table of identifier entries.
    private let table = SymbolTable()
    /// Code generator.
    private let generator = CodeGenerator()
    /// A semantic analyzer.
    private let semanticAnalyzer = SemanticAnalyzer()
    /// `branchLabelCount` backing variable.
    private var _branchLabelCount: Int = 0
    /// Number used to identify the branches (e.g. L1, L2, etc).
    private var branchLabel: String {
        get { _branchLabelCount += 1; return "L\(_branchLabelCount)" }
    }
    /// Whether the semantic analyzer is currently performing analysis inside a function.
    private var functionAnalysisTuple: (memoryHead: Int?, length: Int?)? = nil

    /// Initializes a new instance of
    ///
    /// - Parameter lexicalAnalyzer: A recently initialized lexical analyzer, i.e. one that hasn't read any tokens.
    init?(lexicalAnalyzer: LexicalAnalyzer) {
        self.lexicalAnalyzer = lexicalAnalyzer
    }

    // MARK: Nested Types
    enum BlockContext {
        case program, procedure, function
    }

    /// Analyzes a `<programa>` structure defined in the formal language grammar.
    func analyzeProgram() throws -> [Instruction] {
        generator.reset()
        generator.generateInstruction(.start)
        try readNextTokenIfPossible()
        if let token = self.token {
            guard token.symbol == .s_program else { throw SyntacticError(expected: "`programa`", butFound: token) }
            try readNextTokenIfPossible()
            if let token = self.token {
                guard token.symbol == .s_identifier else { throw SyntacticError(expected: "a program identifier", butFound: token) }
                table.addEntry(ProgramEntry(lexeme: token.lexeme))
                try readNextTokenIfPossible()
                if let token = self.token {
                    guard token.symbol == .s_semicolon else { throw SyntacticError(expected: "`;`", butFound: token) }
                    try analyzeBlock(context: .program) // This already reads the next token
                    if let token = self.token {
                        guard token.symbol == .s_period else { throw SyntacticError(expected: "`.`", butFound: token) }
                        if let token = try lexicalAnalyzer.readNextToken() {
                            throw SyntacticError(expected: "end of file", butFound: token)
                        } else {
                            generator.generateInstruction(.halt)
                            return generator.instructions // Success
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

    func rawInstructions() -> String {
        return generator.output
    }

    /// Analyzes a `<bloco>` structure defined in the formal language grammar.
    private func analyzeBlock(context: BlockContext) throws {
        try readNextTokenIfPossible()
        let variableCount = try analyzeVariableDeclarations()
        let globalVariableCount = generator.globalVariableCount // Freeze
        if let variableCount = variableCount {
            generator.generateInstruction(.alloc(memoryHead: globalVariableCount, length: variableCount))
            generator.globalVariableCount += variableCount
            if context == .function {
                functionAnalysisTuple = (globalVariableCount, variableCount)
            }
        } else if context == .function {
            functionAnalysisTuple = (nil, nil)
        }
        try analyzeSubroutinesDeclarations()
        try analyzeCommands()
        switch (context, variableCount) {
        case (.program, nil): break // Do nothing
        case (.procedure, nil): generator.generateInstruction(.return)
        case (.function, _): break // This is handled in analyzeAssignmentOrProcedureCall
        case (.program, .some(let variableCount)): generator.generateInstruction(.dealloc(memoryHead: globalVariableCount, length: variableCount))
        case (.procedure, .some(let variableCount)):
            generator.generateInstruction(.dealloc(memoryHead: globalVariableCount, length: variableCount))
            generator.generateInstruction(.return)
        }
        if let variableCount = variableCount {
            generator.globalVariableCount -= variableCount
        }
    }

    /// Analyzes a `<etapa de declaração de variáveis>` structure defined in the formal language grammar.
    private func analyzeVariableDeclarations() throws -> Int? {
        var variableCount = 0
        if let token = self.token, token.symbol == .s_var {
            try readNextTokenIfPossible()
            if let token = self.token {
                guard token.symbol == .s_identifier else { throw SyntacticError(expected: "an identifier", butFound: token) }
                while let token = self.token, token.symbol == .s_identifier {
                    variableCount += try analyzeVariables(localVariableCount: variableCount)
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
        return variableCount == 0 ? nil : variableCount
    }

    /// Analyzes a `<declaração de variáveis>` structure defined in the formal language grammar.
    ///
    /// - Returns: Number of variables read.
    private func analyzeVariables(localVariableCount: Int) throws -> Int {
        var variableCount = localVariableCount // Make it mutable
        repeat {
            if let token = self.token {
                guard token.symbol == .s_identifier else { throw SyntacticError(expected: "an identifier", butFound: token) }
                let entry = table.searchDeclaration(of: [ .variable ], with: token.lexeme, in: .local)
                guard entry == nil else { throw SemanticError(message: String(format: NSLocalizedString("Variable `%@` at line %ld was already defined.", comment: ""), token.lexeme, token.line)) }
                let variableIndex = generator.globalVariableCount + variableCount
                variableCount += 1
                table.addEntry(VariableEntry(lexeme: token.lexeme, type: nil, index: variableIndex))
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
        return variableCount
    }

    /// Analyzes a `<tipo>` structure defined in the formal language grammar.
    private func analyzeType() throws {
        if let token = self.token {
            switch token.symbol {
            case .s_integer: table.assignType(.int)
            case .s_boolean: table.assignType(.bool)
            default: throw SyntacticError(expected: "`inteiro` or `booleano`", butFound: token)
            }
            try readNextTokenIfPossible()
        } else {
            throw SyntacticError(expected: "`inteiro` or `booleano`", butFoundEOF: ())
        }
    }

    /// Analyzes a `<etapa de declaração de sub-rotinas>` structure defined in the formal language grammar.
    private func analyzeSubroutinesDeclarations() throws {
        var mainProgramLabel: String? = nil
        if token?.symbol == .s_procedure || token?.symbol == .s_function {
            mainProgramLabel = branchLabel // Freeze
            generator.generateInstruction(.jump(label: mainProgramLabel!))
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
        if let mainProgramLabel = mainProgramLabel {
            generator.generateInstruction(.null(label: mainProgramLabel))
        }
    }

    /// Analyzes a `<declaração de procedimento>` structure defined in the formal language grammar.
    private func analyzeProcedureDeclaration() throws {
        try readNextTokenIfPossible()
        if let token = self.token {
            guard token.symbol == .s_identifier else { throw SyntacticError(expected: "a procedure identifier", butFound: token) }
            let globalEntry = table.searchDeclaration(of: Set(SymbolTable.SearchEntryType.allCases), with: token.lexeme, in: .global)
            switch globalEntry {
            case is ProgramEntry: throw SemanticError(message: String(format: NSLocalizedString("Variable `%@` at line %ld was already defined as a program.", comment: ""), token.lexeme, token.line))
            case is VariableEntry: throw SemanticError(message: String(format: NSLocalizedString("Variable `%@` at line %ld was already defined as a variable.", comment: ""), token.lexeme, token.line))
            case is FunctionEntry: throw SemanticError(message: String(format: NSLocalizedString("Variable `%@` at line %ld was already defined as a function.", comment: ""), token.lexeme, token.line))
            case is ProcedureEntry:
                let localEntry = table.searchDeclaration(of: [ .procedure ], with: token.lexeme, in: .local)
                guard localEntry == nil else { throw SemanticError(message: String(format: NSLocalizedString("Variable `%@` at line %ld was already defined as a local procedure.", comment: ""), token.lexeme, token.line)) }
            default: break // It's nil, which means it wasn't declared previously
            }
            let procedureLabel = branchLabel // Freeze
            table.addEntry(ProcedureEntry(lexeme: token.lexeme, label: procedureLabel))
            generator.generateInstruction(.null(label: procedureLabel))
            try readNextTokenIfPossible()
            if let token = self.token {
                guard token.symbol == .s_semicolon else { throw SyntacticError(expected: "`;`", butFound: token) }
                try analyzeBlock(context: .procedure)
            } else {
                throw SyntacticError(expected: "`;`", butFoundEOF: ())
            }
        } else {
            throw SyntacticError(expected: "a procedure identifier", butFoundEOF: ())
        }
        table.cleanUntilMark()
    }

    /// Analyzes a `<declaração de função>` structure defined in the formal language grammar.
    private func analyzeFunctionDeclaration() throws {
        semanticAnalyzer.startAnalyzing()
        try readNextTokenIfPossible()
        if let functionIdentifierToken = self.token {
            guard functionIdentifierToken.symbol == .s_identifier else { throw SyntacticError(expected: "a function identifier", butFound: functionIdentifierToken) }
            let globalEntry = table.searchDeclaration(of: Set(SymbolTable.SearchEntryType.allCases), with: functionIdentifierToken.lexeme, in: .global)
            switch globalEntry {
            case is ProgramEntry: throw SemanticError(message: String(format: NSLocalizedString("Variable `%@` at line %ld was already defined as a program.", comment: ""), functionIdentifierToken.lexeme, functionIdentifierToken.line))
            case is VariableEntry: throw SemanticError(message: String(format: NSLocalizedString("Variable `%@` at line %ld was already defined as a variable.", comment: ""), functionIdentifierToken.lexeme, functionIdentifierToken.line))
            case is FunctionEntry:
                let localEntry = table.searchDeclaration(of: [ .function ], with: functionIdentifierToken.lexeme, in: .local)
                guard localEntry == nil else { throw SemanticError(message: String(format: NSLocalizedString("Variable `%@` at line %ld was already defined as a local function.", comment: ""), functionIdentifierToken.lexeme, functionIdentifierToken.line)) }
            case is ProcedureEntry: throw SemanticError(message: String(format: NSLocalizedString("Variable `%@` at line %ld was already defined as a procedure.", comment: ""), functionIdentifierToken.lexeme, functionIdentifierToken.line))
            default: break // It's nil, which means it wasn't declared previously
            }
            try readNextTokenIfPossible()
            if let token = self.token {
                guard token.symbol == .s_colon else { throw SyntacticError(expected: "`:`", butFound: token) }
                try readNextTokenIfPossible()
                if let token = self.token {
                    let functionLabel = branchLabel // Freeze
                    let functionEntry: FunctionEntry
                    switch token.symbol {
                    case .s_integer: functionEntry = FunctionEntry(lexeme: functionIdentifierToken.lexeme, type: .int, label: functionLabel)
                    case .s_boolean: functionEntry = FunctionEntry(lexeme: functionIdentifierToken.lexeme, type: .bool, label: functionLabel)
                    default: throw SyntacticError(expected: "`inteiro` or `booleano`", butFound: token)
                    }
                    table.addEntry(functionEntry)
                    generator.generateInstruction(.null(label: functionLabel))
                    try readNextTokenIfPossible()
                    if self.token?.symbol == .s_semicolon {
                        try analyzeBlock(context: .function)
                    } else {
                        // Do nothing
                    }
                    guard semanticAnalyzer.validate() else { throw SemanticError(message: String(format: NSLocalizedString("Missing return in a function declared at line %ld, expected to return `%@`.", comment: ""), functionIdentifierToken.line, functionEntry.type.description)) }
                    functionAnalysisTuple = nil
                    table.cleanUntilMark()
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
            var functionDidReturn = try analyzeSimpleCommand()
            while let token = self.token, token.symbol != .s_end, !functionDidReturn {
                guard token.symbol == .s_semicolon else { throw SyntacticError(expected: "`;`", butFound: token) }
                try readNextTokenIfPossible()
                if self.token?.symbol != .s_end {
                    functionDidReturn = try analyzeSimpleCommand()
                } else {
                    // Do nothing
                }
            }
            if functionDidReturn {
                while self.token?.symbol != .s_end {
                    try readNextTokenIfPossible()
                }
            }
            try readNextTokenIfPossible()
        } else {
            throw SyntacticError(expected: "`inicio`", butFoundEOF: ())
        }
    }

    /// Analyzes a `<comando>` structure defined in the formal language grammar.
    ///
    /// - Returns: Whether a function return (i.e. an assignment made to the function identifier) occurs.
    @discardableResult private func analyzeSimpleCommand() throws -> Bool {
        if token?.symbol == .s_identifier {
            return try analyzeAssignmentOrProcedureCall()
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
        return false
    }

    /// Analyzes a `<atribuição_chprocedimento>` structure defined in the formal language grammar.
    ///
    /// - Returns: Whether a function return (i.e. an assignment made to the function identifier) occurs.
    private func analyzeAssignmentOrProcedureCall() throws -> Bool {
        let previousToken = token! // Freeze
        try readNextTokenIfPossible()
        if token?.symbol == .s_assignment {
            if let variableEntry = table.searchDeclaration(of: [ .variable ], with: previousToken.lexeme, in: .global) as! VariableEntry? {
                // Both local and global variables can be assigned to.
                let assignmentType = try analyzeAssignment()
                guard variableEntry.type == assignmentType else { throw SemanticError(message: String(format: NSLocalizedString("Cannot assign value of type `%@` to type `%@` at line %ld.", comment: ""), assignmentType.description, variableEntry.type.description, token!.line)) }
                generator.generateInstruction(.assign(index: variableEntry.index))
            } else if let functionEntry = table.searchDeclaration(of: [ .function ], with: previousToken.lexeme, in: .local) as! FunctionEntry? {
                // When we're inside a function, a function can be assigned to, and that represents the return of the function.
                let assignmentType = try analyzeAssignment()
                guard functionEntry.type == assignmentType else { throw SemanticError(message: String(format: NSLocalizedString("Cannot assign value of type `%@` to type `%@` at line %ld.", comment: ""), assignmentType.description, functionEntry.type.description, token!.line)) }
                guard let functionAnalysisTuple = functionAnalysisTuple else { throw SemanticError(message: String(format: NSLocalizedString("Cannot assign value to function identifier outside of the function scope. Assignment found at line %ld.", comment: ""), previousToken.line)) }
                semanticAnalyzer.handleReturnStatementFound()
                generator.generateInstruction(.returnFunction(memoryHead: functionAnalysisTuple.memoryHead, length: functionAnalysisTuple.length))
                return true
            } else {
                throw SemanticError(message: String(format: NSLocalizedString("Identifier `%@` at line %ld was used but not declared.", comment: ""), previousToken.lexeme, previousToken.line))
            }
        } else {
            if let procedureEntry = table.searchDeclaration(of: [ .procedure ], with: previousToken.lexeme, in: .global) as! ProcedureEntry? {
                try analyzeProcedureCall()
                generator.generateInstruction(.call(label: procedureEntry.label))
            } else {
                throw SemanticError(message: String(format: NSLocalizedString("Identifier `%@` at line %ld was used but not declared.", comment: ""), previousToken.lexeme, previousToken.line))
            }
        }
        return false
    }

    /// Analyzes a `<comando atribuicao>` structure defined in the formal language grammar.
    private func analyzeAssignment() throws -> Type {
        try readNextTokenIfPossible()
        let assignmentType = try analyzeExpression()
        let postFixedExpression = typeAnalyzer.finalize()
        generator.generateInstructionsForPostFixedExpression(postFixedExpression, symbolTable: table)
        return assignmentType
    }

    /// Analyzes a `<chamada de procedimento>` structure defined in the formal language grammar.
    private func analyzeProcedureCall() throws {
        // TODO: Not implemented yet
    }

    /// Analyzes a `<chamada de função>` structure defined in the formal language grammar.
    private func analyzeFunctionCall() throws {
        try readNextTokenIfPossible()
    }

    /// Analyzes a `<comando condicional>` structure defined in the formal language grammar.
    private func analyzeIf() throws {
        if functionAnalysisTuple != nil { semanticAnalyzer.handleIfStatementFound() }
        let token = self.token // Freeze only to print the line below
        try readNextTokenIfPossible()
        // Defer guarantees the type analysis is properly reset at all cases
        defer { typeAnalyzer.reset() }
        let expressionType = try analyzeExpression()
        // Token is safe to force unwrap below because readNextTokenIfPossible() succeeded
        guard expressionType == .bool else { throw SemanticError(message: String(format: NSLocalizedString("Expression type mismatch: expected a boolean expression at line %ld.", comment: ""), token!.line)) }
        if let token = self.token {
            guard token.symbol == .s_then else { throw SyntacticError(expected: "`entao`", butFound: token) }
            let postFixedExpression = typeAnalyzer.finalize()
            generator.generateInstructionsForPostFixedExpression(postFixedExpression, symbolTable: table)
            let elseLabel = branchLabel // Freeze
            generator.generateInstruction(.jumpIfFalse(label: elseLabel))
            try readNextTokenIfPossible()
            try analyzeSimpleCommand()
            if functionAnalysisTuple != nil { semanticAnalyzer.handleBranchClosing() }
            if self.token?.symbol == .s_else {
                if functionAnalysisTuple != nil { semanticAnalyzer.handleElseStatementFound() }
                let quitIfStatementLabel = branchLabel // Freeze
                generator.generateInstruction(.jump(label: quitIfStatementLabel))
                generator.generateInstruction(.null(label: elseLabel))
                try readNextTokenIfPossible()
                try analyzeSimpleCommand()
                generator.generateInstruction(.null(label: quitIfStatementLabel))
                if functionAnalysisTuple != nil { semanticAnalyzer.handleBranchClosing() }
            } else {
                // The `if` being analyzed doesn't have an `else` (which's fine).
                generator.generateInstruction(.null(label: elseLabel))
            }
        } else {
            throw SyntacticError(expected: "`entao`", butFoundEOF: ())
        }
    }

    /// Analyzes a `<expressão>` structure defined in the formal language grammar.
    private func analyzeExpression() throws -> Type {
        let lastTypeFound = try analyzeSimpleExpression()
        switch token?.symbol {
        case .s_greaterThan?, .s_greaterThanThanOrEqualTo?, .s_equal?, .s_lessThan?, .s_lessThanOrEqualTo?, .s_different?:
            typeAnalyzer.analyzeTerm(token!)
            // Check type of first factor
            guard lastTypeFound == .int else { throw SemanticError(message: String(format: NSLocalizedString("Type mismatch: expected an integer at line %ld.", comment: ""), token!.line)) }
            try readNextTokenIfPossible()
            _ = try analyzeSimpleExpression()
            return .bool
        default: return lastTypeFound
        }
    }

    /// Analyzes a `<expressão simples>` structure defined in the formal language grammar.
    private func analyzeSimpleExpression() throws -> Type {
        let didFindUnary: Bool
        let previousToken = self.token
        if previousToken?.symbol == .s_plus || previousToken?.symbol == .s_minus {
            didFindUnary = true
            typeAnalyzer.analyzeTerm(token!, isUnary: true)
            try readNextTokenIfPossible()
        } else {
            didFindUnary = false
        }
        var lastTypeFound = try analyzeTerm()
        if didFindUnary {
            guard lastTypeFound == .int else { throw SemanticError(message: String(format: NSLocalizedString("Type mismatch: expected an integer term at line %ld after `%@`", comment: ""), previousToken!.line, previousToken!.lexeme)) }
        }
        while token?.symbol == .s_plus || token?.symbol == .s_minus || token?.symbol == .s_or {
            let op = token! // Freeze
            typeAnalyzer.analyzeTerm(op)
            // Check type of first factor
            switch op.symbol {
            case .s_plus, .s_minus: guard lastTypeFound == .int else { throw SemanticError(message: String(format: NSLocalizedString("Type mismatch: expected an integer term at line %ld.", comment: ""), op.line)) }
            case .s_or: guard lastTypeFound == .bool else { throw SemanticError(message: String(format: NSLocalizedString("Type mismatch: expected a boolean term at line %ld.", comment: ""), op.line)) }
            default: preconditionFailure()
            }
            try readNextTokenIfPossible()
            lastTypeFound = try analyzeTerm()
            // Check type of second factor
            switch op.symbol {
            case .s_plus, .s_minus: guard lastTypeFound == .int else { throw SemanticError(message: String(format: NSLocalizedString("Type mismatch: expected an integer term at line %ld.", comment: ""), op.line)) }
            case .s_or: guard lastTypeFound == .bool else { throw SemanticError(message: String(format: NSLocalizedString("Type mismatch: expected a boolean term at line %ld.", comment: ""), op.line)) }
            default: preconditionFailure()
            }
        }
        return lastTypeFound // Any type found would work here, because if we reached this step, it means all types matched so far
    }

    /// Analyzes a `<termo>` structure defined in the formal language grammar.
    private func analyzeTerm() throws -> Type {
        var lastTypeFound = try analyzeFactor()
        while token?.symbol == .s_multiplication || token?.symbol == .s_division || token?.symbol == .s_and {
            let op = token! // Freeze
            typeAnalyzer.analyzeTerm(op)
            // Check type of first factor
            switch op.symbol {
            case .s_multiplication, .s_division: guard lastTypeFound == .int else { throw SemanticError(message: String(format: NSLocalizedString("Type mismatch: expected an integer term at line %ld.", comment: ""), op.line)) }
            case .s_and: guard lastTypeFound == .bool else { throw SemanticError(message: String(format: NSLocalizedString("Type mismatch: expected a boolean term at line %ld.", comment: ""), op.line)) }
            default: preconditionFailure()
            }
            try readNextTokenIfPossible()
            lastTypeFound = try analyzeFactor()
            // Check type of second factor
            switch op.symbol {
            case .s_multiplication, .s_division: guard lastTypeFound == .int else { throw SemanticError(message: String(format: NSLocalizedString("Type mismatch: expected an integer term at line %ld.", comment: ""), op.line)) }
            case .s_and: guard lastTypeFound == .bool else { throw SemanticError(message: String(format: NSLocalizedString("Type mismatch: expected a boolean term at line %ld.", comment: ""), op.line)) }
            default: preconditionFailure()
            }
        }
        return lastTypeFound // Any type found would work here, because if we reached this step, it means all types matched so far
    }

    /// Analyzes a `<fator>` structure defined in the formal language grammar.
    private func analyzeFactor() throws -> Type {
        if let token = token {
            if token.symbol == .s_identifier {
                typeAnalyzer.analyzeTerm(token)
                // Must be a variable or a function
                let typedEntry = table.searchDeclaration(of: [ .variable, .function ], with: token.lexeme, in: .global) as! TypedEntry?
                switch typedEntry {
                case is FunctionEntry: try analyzeFunctionCall()
                case is VariableEntry: try readNextTokenIfPossible()
                default: throw SemanticError(message: String(format: NSLocalizedString("Identifier `%@` at line %ld is being used but was never declared.", comment: ""), token.lexeme, token.line))
                }
                switch typedEntry?.type {
                case .int?: return .int
                case .bool?: return .bool
                case nil: preconditionFailure()
                }
            } else if token.symbol == .s_number {
                typeAnalyzer.analyzeTerm(token)
                try readNextTokenIfPossible()
                return .int
            } else if token.symbol == .s_not {
                typeAnalyzer.analyzeTerm(token)
                try readNextTokenIfPossible()
                let factorType = try analyzeFactor()
                guard factorType == .bool else { throw SemanticError(message: String(format: NSLocalizedString("Type mismatch: expected a boolean expression at line %ld because `nao` can only be applied to boolean types.", comment: ""), token.line)) }
                return factorType
            } else if token.symbol == .s_left_parenthesis {
                typeAnalyzer.analyzeTerm(token)
                // Expression between parenthesis
                try readNextTokenIfPossible()
                let expressionType = try analyzeExpression()
                if let token = self.token {
                    guard token.symbol == .s_right_parenthesis else { throw SyntacticError(expected: "`)`", butFound: token) }
                    typeAnalyzer.analyzeTerm(token)
                    try readNextTokenIfPossible()
                    return expressionType
                } else {
                    throw SyntacticError(expected: "`)`", butFoundEOF: ())
                }
            } else if token.symbol == .s_true || token.symbol == .s_false {
                typeAnalyzer.analyzeTerm(token)
                try readNextTokenIfPossible()
                return .bool
            } else {
                throw SyntacticError(expected: "an identifier, or a number, or `nao`, or `(`, or `true` or `false`", butFound: token)
            }
        } else {
            throw SyntacticError(expected: "an identifier, or a number, or `nao`, or `(`, or `true` or `false`", butFoundEOF: ())
        }
    }

    /// Analyzes a `<comando repetição>` structure defined in the formal language grammar.
    private func analyzeWhile() throws {
        let token = self.token // Freeze only to print the line below
        try readNextTokenIfPossible()
        // Defer guarantees the type analysis is properly reset at all cases
        defer { typeAnalyzer.reset() }
        let expressionEvaluationLabel = branchLabel // Freeze
        generator.generateInstruction(.null(label: expressionEvaluationLabel))
        let expressionType = try analyzeExpression()
        // Token is safe to force unwrap below because readNextTokenIfPossible() succeeded
        guard expressionType == .bool else { throw SemanticError(message: String(format: NSLocalizedString("Type mismatch: expected a boolean expression at line %ld.", comment: ""), token!.line)) }
        if let token = self.token {
            guard token.symbol == .s_do else { throw SyntacticError(expected: "`faca`", butFound: token) }

            let postFixedExpression = typeAnalyzer.finalize()
            generator.generateInstructionsForPostFixedExpression(postFixedExpression, symbolTable: table)

            let quitWhileStatementLabel = branchLabel // Freeze
            generator.generateInstruction(.jumpIfFalse(label: quitWhileStatementLabel))

            try readNextTokenIfPossible()
            try analyzeSimpleCommand()

            generator.generateInstruction(.jump(label: expressionEvaluationLabel))
            generator.generateInstruction(.null(label: quitWhileStatementLabel))
        } else {
            throw SyntacticError(expected: "`faca`", butFoundEOF: ())
        }
    }

    /// Analyzes a `<comando leitura>` structure defined in the formal language grammar.
    private func analyzeRead() throws {
        generator.generateInstruction(.read)
        try readNextTokenIfPossible()
        if let token = self.token {
            guard token.symbol == .s_left_parenthesis else { throw SyntacticError(expected: "`(`", butFound: token) }
            try readNextTokenIfPossible()
            if let token = self.token {
                guard token.symbol == .s_identifier else { throw SyntacticError(expected: "an identifier", butFound: token) }
                guard let variableEntry = table.searchDeclaration(of: [ .variable ], with: token.lexeme, in: .global) as! VariableEntry? else { throw SemanticError(message: String(format: NSLocalizedString("Variable `%@` at line %ld is being used but was never defined.", comment: ""), token.lexeme, token.line)) }
                guard variableEntry.type == .int else { throw SemanticError(message: String(format: NSLocalizedString("Variable `%@` being read at line %ld must be an integer.", comment: ""), token.lexeme, token.line)) }
                generator.generateInstruction(.assign(index: variableEntry.index))
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
                guard let typedEntry = table.searchDeclaration(of: [ .variable, .function ], with: token.lexeme, in: .global) as! TypedEntry? else { throw SemanticError(message: String(format: NSLocalizedString("Identifier `%@` at line %ld is being used but was never defined.", comment: ""), token.lexeme, token.line)) }
                guard typedEntry.type == .int else { throw SemanticError(message: String(format: NSLocalizedString("Variable `%@` being written at line %ld must be an integer.", comment: ""), token.lexeme, token.line)) }
                if let variableEntry = typedEntry as? VariableEntry {
                    generator.generateInstruction(.loadValue(index: variableEntry.index))
                } else if let functionEntry = typedEntry as? FunctionEntry {
                    generator.generateInstruction(.call(label: functionEntry.label))
                } else {
                    preconditionFailure()
                }
                generator.generateInstruction(.print)
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
