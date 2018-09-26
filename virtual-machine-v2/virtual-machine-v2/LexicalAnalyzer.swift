//
//  LexicalAnalyzer.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 18/09/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation

final class LexicalAnalyzer {
    /// The source code that is being interpreted by the lexical analyzer.
    private var sourceCode: Substring
    /// A dictionary of tokens, keyed by the lexeme of the token.
    private var tokenTable: [String:Token] = [:]
    /// Contains the current (last read) character.
    var character: Character!
    /// The current line being read.
    private var line: UInt = 1
    /// Whether the parser has already reached the end of file successfully (i.e. found a finalization period and nothing after it).
    private var didReachEOF: Bool = false

    init?(sourceCode: String) {
        guard !sourceCode.isEmpty else { return nil }
        self.sourceCode = sourceCode[sourceCode.startIndex...]
        character = readNextCharacter()
    }

    /// Processes the source code to parse the next token, assigns the token read to its instance variable and adds it to the token table.
    ///
    /// - Returns: The token read, or nil if we reached the end of the file.
    /// - Throws: Throws an error in case it can't read the next token due to lexical problems.
    @discardableResult func readNextToken() throws -> Token? {
        guard !didReachEOF else { return nil }
        // 1. Eliminate all comments, whitespaces and new lines
        while !didReachEOF && (character == "{" || character.isWhitespace) {
            if character == "{" {
                while !didReachEOF && character != "}" {
                    if character == "\r\n" {
                        line += 1
                    }
                    character = readNextCharacter()
                    if character == nil {
                        throw LexicalError(message: NSLocalizedString("Expected `}` but it couldn't be found in the whole file at line \(line).", comment: ""))
                    }
                }
                character = readNextCharacter()
            }
            while !didReachEOF && character.isWhitespace {
                if character == "\r\n" {
                    line += 1
                }
                character = readNextCharacter()
            }
        }
        guard !didReachEOF else { return nil }
        // 2. Read next token
        let token = try parseToken()
        // 3. Add the token to the token table
        tokenTable[token.lexeme] = token
        return token
    }

    /// Processes the source code to read parse the next character.
    ///
    /// - Returns: The character read.
    /// - Throws: Throws in case the next character can't be read, i.e. due to having reached the end of the file.
    private func readNextCharacter() -> Character? {
        if let result = sourceCode.first {
            sourceCode.removeFirst()
            return result
        } else {
            didReachEOF = true
            return nil
        }
    }

    /// Caution: all the algos gotta read the next character in the end.

    /// Parses the next sequence of characters into a token, if possible.
    ///
    /// - Returns: The token processed from the next sequence of characters.
    /// - Throws: Throws for symbols that don't belong to the language described in this compiler.
    private func parseToken() throws -> Token {
        if character.isDigit {
            return handleDigit()
        } else if character.belongsToIdentifierCharacterSet {
            return handleIdentifier()
        } else {
            switch character {
            case ":": return handleAssignment()
            case "+", "-", "*": return handleArithmeticOperator()
            case "<", ">", "=", "!": return try handleRelationalOperator()
            case ";", ",", "(", ")", ".": return handleOtherCharacter()
            default: throw LexicalError(message: NSLocalizedString("Unexpected symbol found: \(character!) at line \(line)", comment: ""))
            }
        }
    }

    /// Processes digit characters, i.e. all digits from 0 to 9.
    ///
    /// - Returns: The token processed from this character.
    /// - Precondition: The current character must be a digit.
    private func handleDigit() -> Token {
        var lexeme = String(character)
        character = readNextCharacter()
        while character != nil && character.isDigit {
            lexeme += String(character)
            character = readNextCharacter()
        }
        return Token(symbol: .s_number, lexeme: lexeme, line: line)
    }

    /// Processes an identifier, including variable and procedure names, and keywords.
    ///
    /// - Returns: The token processed from this character.
    /// - Precondition: The current character must be a letter.
    private func handleIdentifier() -> Token {
        var lexeme = String(character)
        character = readNextCharacter()
        while character != nil && character.belongsToIdentifierCharacterSet {
            lexeme += String(character)
            character = readNextCharacter()
        }
        let symbol: Token.Symbol = {
            switch lexeme {
            case "programa": return .s_program
            case "se": return .s_if
            case "entao": return .s_then
            case "senao": return .s_else
            case "enquanto": return .s_while
            case "faca": return .s_do
            case "inicio": return .s_start
            case "fim": return .s_end
            case "escreva": return .s_write
            case "leia": return .s_read
            case "var": return .s_var
            case "inteiro": return .s_integer
            case "booleano": return .s_boolean
            case "verdadeiro": return .s_true
            case "falso": return .s_false
            case "procedimento": return .s_procedure
            case "funcao": return .s_function
            case "div": return .s_division
            case "e": return .s_and
            case "ou": return .s_or
            case "nao": return .s_not
            default: return .s_identifier
            }
        }()
        return Token(symbol: symbol, lexeme: lexeme, line: line)
    }

    /// Processes the character `:` and its subsequent character, if it's a `=`.
    ///
    /// - Returns: The token processed from this character.
    /// - Precondition: Requires the current character to be `:`.
    private func handleAssignment() -> Token {
        var lexeme = String(character)
        character = readNextCharacter()
        let symbol: Token.Symbol = {
            if character == "=" {
                lexeme += String(character)
                character = readNextCharacter()
                return .s_assignment
            } else {
                return .s_colon
            }
        }()
        return Token(symbol: symbol, lexeme: lexeme, line: line)
    }

    /// Processes the characters `+`, `-`, and `*`.
    ///
    /// - Returns: The token processed from this character.
    /// - Precondition: Requires the current character to be either `+`, `-`, or `*`.
    private func handleArithmeticOperator() -> Token {
        let lexeme = String(character)
        let symbol: Token.Symbol = {
            switch lexeme {
            case "+": return .s_plus
            case "-": return .s_minus
            case "*": return .s_multiplication
            default: preconditionFailure()
            }
        }()
        character = readNextCharacter()
        return Token(symbol: symbol, lexeme: lexeme, line: line)
    }

    /// Processes the characters `=`, `<=`, `>=`, `<`, `>` and `!=`.
    ///
    /// - Returns: The token processed from this character, if possible.
    /// - Precondition: Requires the current character to be either `<`, `>`, `=` or `!`.
    /// - Throws: Throws in case the character following a `!` character isn't a `=`.
    private func handleRelationalOperator() throws -> Token {
        var relationalOperator = String(character)
        let symbol: Token.Symbol
        var nextCharacter = readNextCharacter()
        // NOTE: the precedence of the cases matters here!
        switch (relationalOperator, nextCharacter) {
        case ("=", _): symbol = .s_equal
        case ("<", "="):
            relationalOperator += String(nextCharacter!)
            symbol = .s_lesserThanOrEqualTo
            nextCharacter = readNextCharacter()
        case (">", "="):
            relationalOperator += String(nextCharacter!)
            symbol = .s_greaterThanOrEqualTo
            nextCharacter = readNextCharacter()
        case ("<", _): symbol = .s_lesser
        case (">", _): symbol = .s_greater
        case ("!", "="):
            relationalOperator += String(nextCharacter!)
            symbol = .s_different
            nextCharacter = readNextCharacter()
        default:
            switch (relationalOperator, nextCharacter) {
            case ("!", _): throw LexicalError(message: NSLocalizedString("Expected `=` after `!`, but found \(nextCharacter != nil ? "`\(nextCharacter!)`" : "nothing") at line \(line).", comment: ""))
            default: throw LexicalError(message: NSLocalizedString("An unexpected error happened at line \(line).", comment: "")) // This error would break the precondition of this function
            }
        }
        character = nextCharacter
        return Token(symbol: symbol, lexeme: relationalOperator, line: line)
    }

    /// Processes the characters `;`, `,`, `(`, `)`, and `.`.
    ///
    /// - Returns: The token processed from this character.
    /// - Precondition: Requires the current character to be either `;`, `,`, `(`, `)`, or `.`.
    private func handleOtherCharacter() -> Token {
        let lexeme = String(character)
        let symbol: Token.Symbol = {
            switch lexeme {
            case ";": return .s_semicolon
            case ",": return .s_comma
            case "(": return .s_left_parenthesis
            case ")": return .s_right_parenthesis
            case ".": return .s_period
            default: preconditionFailure()
            }
        }()
        character = readNextCharacter()
        return Token(symbol: symbol, lexeme: lexeme, line: line)
    }
}

private extension Character {
    /// Whether the character is a digit, i.e. a number between 0 and 9.
    var isDigit: Bool {
        guard let firstUnicodeScalar = unicodeScalars.first else { return false }
        return CharacterSet.decimalDigits.contains(firstUnicodeScalar)
    }

    /// Whether the character belongs to the identifier character set, i.e. an alphanumeric or underscore character.
    var belongsToIdentifierCharacterSet: Bool {
        let identifierCharacterSet: CharacterSet = {
            var result = CharacterSet.alphanumerics // Must be mutable
            result.formUnion(CharacterSet(charactersIn: "_"))
            return result
        }()
        guard let firstUnicodeScalar = unicodeScalars.first else { return false }
        return identifierCharacterSet.contains(firstUnicodeScalar)
    }

    /// Whether the character is a whitespace, e.g. space, line break, carriage return, etc.
    var isWhitespace: Bool {
        guard let firstUnicodeScalar = unicodeScalars.first else { return false }
        return CharacterSet.whitespacesAndNewlines.contains(firstUnicodeScalar)
    }
}
