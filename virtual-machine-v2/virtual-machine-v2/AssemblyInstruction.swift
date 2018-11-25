//
//  AssemblyInstruction.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 21/11/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation

// FIXME: Merge Instruction into this (or vice versa)
enum AssemblyInstruction : Hashable {
    case loadConstant(constant: String)
    case loadValue(index: Int)
    case add
    case subtract
    case multiply
    case divide
    case invert
    case and
    case or
    case negate
    case compareLessThan
    case compareGreaterThan
    case compareEqual
    case compareDifferent
    case compareLessThanOrEqualTo
    case compareGreaterThanOrEqualTo
    case start
    case halt
    case assign(index: Int)
    case jump(label: String)
    case jumpIfFalse(label: String)
    case null(label: String)
    case read
    case print
    case alloc(memoryHead: Int, length: Int)
    case dealloc(memoryHead: Int, length: Int)
    case call(label: String)
    case `return`
    case returnFunction(memoryHead: Int?, length: Int?)

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
        case .compareLessThan: return "CME"
        case .compareGreaterThan: return "CMA"
        case .compareEqual: return "CEQ"
        case .compareDifferent: return "CDIF"
        case .compareLessThanOrEqualTo: return "CMEQ"
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
        case .returnFunction: return "RETURNF"
        }
    }

    var argument1: String? {
        switch self {
        case .loadConstant(let constant): return "\(constant)"
        case .loadValue(let memoryIndex): return String(memoryIndex)
        case .assign(let memoryIndex): return String(memoryIndex)
        case .jump(let instructionPoint): return String(instructionPoint)
        case .jumpIfFalse(let instructionPoint): return String(instructionPoint)
        case .null(let label): return label
        case .alloc(let memoryHead, _): return String(memoryHead)
        case .dealloc(let memoryHead, _): return String(memoryHead)
        case .returnFunction(let memoryHead, _): return memoryHead != nil ? String(memoryHead!) : nil
        case .call(let instructionPoint): return String(instructionPoint)
        case .add, .subtract, .multiply, .divide, .invert, .and, .or, .negate,
             .compareLessThan, .compareGreaterThan, .compareEqual, .compareDifferent,
             .compareLessThanOrEqualTo, .compareGreaterThanOrEqualTo, .start,
             .halt, .read, .print, .return: return nil
        }
    }

    var argument2: String? {
        switch self {
        case .alloc(_, let length): return String(length)
        case .dealloc(_, let length): return String(length)
        case .returnFunction(_, let length): return length != nil ? String(length!) : nil
        case .loadConstant, .loadValue, .add, .subtract, .multiply, .divide,
             .invert, .and, .or, .negate, .compareLessThan, .compareGreaterThan,
             .compareEqual, .compareDifferent, .compareLessThanOrEqualTo,
             .compareGreaterThanOrEqualTo, .start, .halt, .assign, .jump,
             .jumpIfFalse, .null, .read, .print, .call, .return: return nil
        }
    }

    var hasNoArguments: Bool {
        return argument1 == nil && argument2 == nil
    }

    var hasStrictlyOneArgument: Bool {
        return argument1 != nil && argument2 == nil
    }

    var hasStrictlyTwoArguments: Bool {
        return argument1 != nil && argument2 != nil
    }
}
