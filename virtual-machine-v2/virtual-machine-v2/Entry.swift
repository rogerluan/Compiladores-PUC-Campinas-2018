//
//  Entry.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 17/10/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation

// MARK: Protocols
/// A class protocol to determine whether the class can be marked.
protocol Markable : class {
    /// Whether the entry is marked or not. Defaults to `true`.
    var isMarked: Bool { get set }
    /// Sets the `isMarked` flag to `false`.
    func removeMark()
}

extension Markable {

    func removeMark() {
        isMarked = false
    }
}

/// An entry in the symbol table.
protocol Entry {
    /// The token's lexeme.
    var lexeme: String { get set }
}

/// Some entries may have types (i.e. function and variable entries), thus should conform to this protocol.
protocol TypedEntry : class, Entry {
    /// All classes conforming to TypedEntry must assign the type before accessing it,
    /// even though in certain scenarios (i.e. variable entries) it's not possible to
    /// initialize it passing the type argument directly in the initializer (because
    /// it's not yet known).
    var type: Type! { get set }
}

/// A class protocol to determine whether the entry can be called (i.e. jumped to).
protocol CallableEntry : class {
    /// The label that identifies the beginning of this entry's code.
    var label: String { get set }
}




// MARK: Declarations
final class FunctionEntry : TypedEntry, CallableEntry, Markable {
    var isMarked: Bool = true
    var lexeme: String
    var type: Type!
    var label: String

    init(lexeme: String, type: Type, label: String) {
        self.lexeme = lexeme
        self.type = type
        self.label = label
    }

    // Equatable Conforming
    static func == (lhs: FunctionEntry, rhs: FunctionEntry) -> Bool {
        return lhs.lexeme == rhs.lexeme
    }

    // Hashable Conforming
    public var hashValue: Int { return lexeme.hash }
}

final class VariableEntry : TypedEntry {
    var lexeme: String
    var type: Type!

    init(lexeme: String, type: Type?) {
        self.lexeme = lexeme
        self.type = type
    }
}

final class ProcedureEntry : Entry, CallableEntry, Markable {
    var isMarked: Bool = true
    var lexeme: String
    var label: String

    init(lexeme: String, label: String) {
        self.lexeme = lexeme
        self.label = label
    }

    // Equatable Conforming
    static func == (lhs: ProcedureEntry, rhs: ProcedureEntry) -> Bool {
        return lhs.lexeme == rhs.lexeme
    }

    // Hashable Conforming
    public var hashValue: Int { return lexeme.hash }
}

final class ProgramEntry : Entry, Markable {
    var isMarked: Bool = true
    var lexeme: String

    init(lexeme: String) {
        self.lexeme = lexeme
    }

    // Equatable Conforming
    static func == (lhs: ProgramEntry, rhs: ProgramEntry) -> Bool {
        return lhs.lexeme == rhs.lexeme
    }

    // Hashable Conforming
    public var hashValue: Int { return lexeme.hash }
}
