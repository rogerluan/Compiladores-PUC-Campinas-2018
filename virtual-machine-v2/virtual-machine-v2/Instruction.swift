//
//  Instruction.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 15/08/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation

indirect enum Instruction : Hashable {
    /// s = s + 1; M[s] = k
    case loadConstant(Decimal)
    /// s = s + 1; M[s] = M[n]
    case loadValue(memoryIndex: Int)
    /// M[s-1] = M[s-1] + M[s]; s = s - 1
    case add
    /// M[s-1] = M[s-1] - M[s]; s = s - 1
    case subtract
    /// M[s-1] = M[s-1] * M[s]; s = s - 1
    case multiply
    /// M[s-1] = M[s-1] / M[s]; s = s - 1
    case divide
    /// M[s] = -M[s]
    case invert
    /// If (M[s-1] == 1 and M[s] == 1) then M[s-1] = 1 else M[s-1] = 0; s = s - 1
    case and
    /// If (M[s-1] == 1 or M[s] == 1) then M[s-1] = 1 else M[s-1] = 0; s = s - 1
    case or
    /// M[s] = 1 - M[s]
    case negate
    /// If (M[s-1] < M[s]) then M[s-1] = 1 else M[s-1] = 0; s = s - 1
    case compareLesserThan
    /// If (M[s-1] > M[s]) then M[s-1] = 1 else M[s-1] = 0; s = s - 1
    case compareGreaterThan
    /// If (M[s-1] == M[s]) then M[s-1] = 1 else M[s-1] = 0; s = s - 1
    case compareEqual
    /// If (M[s-1] != M[s]) then M[s-1] = 1 else M[s-1] = 0; s = s - 1
    case compareDifferent
    /// If (M[s-1] ≤ M[s]) then M[s-1] = 1 else M[s-1] = 0; s = s - 1
    case compareLesserThanOrEqualTo
    /// If (M[s-1] ≥ M[s]) then M[s-1] = 1 else M[s-1] = 0; s = s - 1
    case compareGreaterThanOrEqualTo
    /// S = -1
    case start
    /// Stop the execution of the virtual machine.
    case halt
    /// Assign M[s] into the given memory position. M[n] = M[s]; s = s - 1
    case assign(memoryIndex: Int)
    /// i = t
    case jump(instructionIndex: Int)
    /// If (M[s] == 0) then i = t else i = i + 1; s = s - 1
    case jumpIfFalse(instructionIndex: Int)
    /// No-op
    case null
    /// s = s + 1; M[s] = “next value read from user input”
    case read
    /// Print M[s]; s = s - 1
    case print
    /// Copy a memory array of the given length, starting at the given memory head, into another memory range starting at s = s + 1
    case alloc(memoryHead: Int, length: Int)
    /// Copy a memory range of the given length, starting at M[s], into a memory array starting at the given memory head. Then s = s - 1
    case dealloc(memoryHead: Int, length: Int)
    /// s = s + 1; M[s] = currentInstructionPosition + 1; Instructionp[currentInstructionPosition] = instruction
    case call(instructionIndex: Int)
    /// Return from a procedure.
    case `return`

    init?(rawInstruction: String) {
        let components: [String] = rawInstruction.split(separator: " ", omittingEmptySubsequences: true).map { String($0) }
        guard let opcode = components.first?.uppercased() else { return nil }
        switch opcode {
        case "LDC":
            guard let constant = Decimal(string: components[1]) else { return nil }
            self = .loadConstant(constant)
        case "LDV":
            guard let memoryIndex = Int(components[1]) else { return nil }
            self = .loadValue(memoryIndex: memoryIndex)
        case "ADD": self = .add
        case "SUB": self = .subtract
        case "MULT": self = .multiply
        case "DIVI": self = .divide
        case "INV": self = .invert
        case "AND": self = .and
        case "OR": self = .or
        case "NEG": self = .negate
        case "CME": self = .compareLesserThan
        case "CMA": self = .compareGreaterThan
        case "CEQ": self = .compareEqual
        case "CDIF": self = .compareDifferent
        case "CMEQ": self = .compareLesserThanOrEqualTo
        case "CMAQ": self = .compareGreaterThanOrEqualTo
        case "START": self = .start
        case "HLT": self = .halt
        case "STR":
            guard let memoryIndex = Int(components[1]) else { return nil }
            self = .assign(memoryIndex: memoryIndex)
        case "JMP":
            guard let instructionIndex = Int(components[1]) else { return nil }
            self = .jump(instructionIndex: instructionIndex)
        case "JMPF":
            guard let instructionIndex = Int(components[1]) else { return nil }
            self = .jumpIfFalse(instructionIndex: instructionIndex)
        case "NULL": self = .null
        case "RD": self = .read
        case "PRN": self = .print
        case "ALLOC":
            guard let memoryHead = Int(components[1]), let length = Int(components[2]) else { return nil }
            self = .alloc(memoryHead: memoryHead, length: length)
        case "DALLOC":
            guard let memoryHead = Int(components[1]), let length = Int(components[2]) else { return nil }
            self = .dealloc(memoryHead: memoryHead, length: length)
        case "CALL":
            guard let instructionIndex = Int(components[1]) else { return nil }
            self = .call(instructionIndex: instructionIndex)
        case "RETURN": self = .return
        default: return nil
        }
    }

    var opcode: String {
        switch self {
        case .loadConstant: return "LDC"
        case .loadValue: return "LDV"
        case .add: return "ADD"
        case .subtract: return "SUB"
        case .multiply: return "MULT"
        case .divide: return "DIVI"
        case .invert: return "INV"
        case .and: return "AND"
        case .or: return "OR"
        case .negate: return "NEG"
        case .compareLesserThan: return "CME"
        case .compareGreaterThan: return "CMA"
        case .compareEqual: return "CEQ"
        case .compareDifferent: return "CDIF"
        case .compareLesserThanOrEqualTo: return "CMEQ"
        case .compareGreaterThanOrEqualTo: return "CMAQ"
        case .start: return "START"
        case .halt: return "HLT"
        case .assign: return "STR"
        case .jump: return "JMP"
        case .jumpIfFalse: return "JMPF"
        case .null: return "NULL"
        case .read: return "RD"
        case .print: return "PRN"
        case .alloc: return "ALLOC"
        case .dealloc: return "DALLOC"
        case .call: return "CALL"
        case .return: return "RETURN"
        }
    }

    var argument1: String {
        switch self {
        case .loadConstant(let constant): return "\(constant)"
        case .loadValue(let memoryIndex): return String(memoryIndex)
        case .assign(let memoryIndex): return String(memoryIndex)
        case .jump(let instructionPoint): return String(instructionPoint)
        case .jumpIfFalse(let instructionPoint): return String(instructionPoint)
        case .alloc(let memoryHead, _): return String(memoryHead)
        case .dealloc(let memoryHead, _): return String(memoryHead)
        case .call(let instructionPoint): return String(instructionPoint)
        case .add, .subtract, .multiply, .divide, .invert, .and, .or, .negate,
             .compareLesserThan, .compareGreaterThan, .compareEqual, .compareDifferent,
             .compareLesserThanOrEqualTo, .compareGreaterThanOrEqualTo, .start,
             .halt, .null, .read, .print, .return: return ""
        }
    }

    var argument2: String {
        switch self {
        case .alloc(_, let length): return String(length)
        case .dealloc(_, let length): return String(length)
        case .loadConstant, .loadValue, .add, .subtract, .multiply, .divide,
             .invert, .and, .or, .negate, .compareLesserThan, .compareGreaterThan,
             .compareEqual, .compareDifferent, .compareLesserThanOrEqualTo,
             .compareGreaterThanOrEqualTo, .start, .halt, .assign, .jump,
             .jumpIfFalse, .null, .read, .print, .call, .return: return ""
        }
    }
}
