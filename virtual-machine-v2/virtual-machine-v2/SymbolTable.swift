//
//  SymbolTable.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 24/10/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation

final class SymbolTable {
    private var stack: [Entry] = []

    /// Adds a new entry to the symbol table.
    func addEntry(_ entry: Entry) {
        stack.append(entry)
    }

    /// Assign the given type to all the typed entries that still have no types.
    func assignType(_ type: Type) {
        stack.compactMap { $0 as? TypedEntry }.forEach { typedEntry in
            typedEntry.type = typedEntry.type ?? type
        }
    }

    /// Searches for a previously declared entry of the given types that has the given lexeme (identifier), within the given scope.
    ///
    /// - Parameters:
    ///   - entryTypes: The types of entries that this search will look for.
    ///   - lexeme: The lexeme (identifier) that is being looked up.
    ///   - scope: The scope of the search, which can be either local or global.
    /// - Returns: Returns the found entry, if any.
    func searchDeclaration(of entryTypes: Set<SearchEntryType>, with lexeme: String, in scope: Scope) -> Entry? {
        let scopedStack: [Entry] = {
            switch scope {
            case .local:
                // Since the splitting is limited to 1 split, this returns [ArraySlice<Entry>] of max count of 2, the first being the
                // local stack, and the second, if existent, consists of all the "other" stacks.
                stack.reverse() // Reverse because the method below splits starting from the first (as in a FIFO), and we need to split starting from last (as in a LIFO)
                defer { stack.reverse() } // Revert the reversion as a last command
                let localAndOtherStacks = stack.splitAt {
                    guard let markableEntry = $0 as? Markable else { return false }
                    return markableEntry.isMarked
                }
                let localStack = localAndOtherStacks.first! // Assumedly there's always a first stack because Program is marked.
                return Array(localStack)
            case .global: return stack
            }
        }()
        // Search for last, but because this is a stack, it's actually the first (from top to bottom).
        let firstVariableFoundInScope = scopedStack.last { entry in
            let belongsToTheSearchedType: Bool = {
                return entryTypes.contains { entryType in
                    switch entryType {
                    case .program: return entry is ProgramEntry
                    case .variable: return entry is VariableEntry
                    case .function: return entry is FunctionEntry
                    case .procedure: return entry is ProcedureEntry
                    }
                }
            }()
            return belongsToTheSearchedType && entry.lexeme == lexeme
        }
        return firstVariableFoundInScope
    }

    /// Pops the entries of the stack, until a mark is found. Once it is found, it doesn't drop the entry that has the mark, but removes its mark instead.
    ///
    /// This strategy is used to control scope of variable declarations.
    func cleanUntilMark() {
        // Reverse the stack because drop(while:) drops starting from the first (as in a FIFO), and we need to drop starting from last (as in a LIFO)
        stack.reverse()
        let cleanedStack = stack.drop { entry -> Bool in
            (entry as? Markable)?.isMarked != true
        }
        (cleanedStack.first as? Markable)?.removeMark()
        // Reverse it back to keep the correct order of the stack
        stack = Array(cleanedStack.reversed())
    }

    // MARK: Nested Types

    /// Entry type of the lexeme being searched for.
    enum SearchEntryType : Hashable, CaseIterable {
        case program
        case variable
        case function
        case procedure
    }

    /// Scope where the lexeme search must be done.
    enum Scope {
        case local, global
    }
}
