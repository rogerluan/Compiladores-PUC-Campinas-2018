//
//  Engine.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 22/08/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation
import UIKit

final class Engine {
    static let shared = Engine()
    /// A stack that represents the memory of the virtual machine.
    var memory: [Decimal] = [] { didSet { memoryChangedHandler?() } } // Public because it's used as the MemoryTableView's data source.
    /// Instructions to be executed and whether it has a breakpoint or not
    private var instructions: [(Instruction, Bool)] = []
    /// Memory index.
    var s: Int = 0 { didSet { memoryChangedHandler?() } }
    /// Program conter index.
    private var i: Int = 0 { didSet { programCounterChangedHandler?(i) } }
    private var labelMap: [String:Int] = [:]

    var finishHandler: (() -> Void)? = nil
    var readHandler: (() -> Void)? = nil
    var printHandler: ((Decimal) -> Void)? = nil
    var memoryChangedHandler: (() -> Void)? = nil
    var programCounterChangedHandler: ((Int) -> Void)? = nil
    var executionPausedHandler: ((Int) -> Void)? = nil

    func process(text: String) -> [Instruction] {
        let lines: [String] = text.split(separator: "\n", omittingEmptySubsequences: true).map { String($0) }
        guard let instructions = lines.failableMap({ Instruction(rawInstruction: $0) }) else { return [] }
        return instructions
    }

    func setBreakpoint(active: Bool, at line: Int) {
        guard instructions.indices.contains(line) else { return }
        instructions[line].1 = active
    }

    func hasBreakpoint(at line: Int) -> Bool {
        guard instructions.indices.contains(line) else { return false }
        return instructions[line].1
    }

    func execute(instructions: [Instruction], stepByStep: Bool) throws {
        reset()
        // Populate the label map
        for (index, instruction) in instructions.enumerated() {
            switch instruction {
            case .null(let label): labelMap[label] = index + 1 // Line numbers start at 0
            default: break
            }
        }
        let breakpoints = Array(repeating: stepByStep, count: instructions.count)
        self.instructions = Array(zip(instructions, breakpoints))
        try executeNextInstruction()
    }

    func executeNextInstruction() throws {
        let nextInstruction = instructions[i]
        if nextInstruction.1 {
            // This instruction has a breakpoint, wait to execute it
            executionPausedHandler?(i)
        } else {
            try execute(instruction: nextInstruction.0)
        }
    }

    func continueExecution() throws {
        let nextInstruction = instructions[i]
        try execute(instruction: nextInstruction.0)
    }

    private func execute(instruction: Instruction) throws {
        var nextInstructionIndex = i + 1
        switch instruction {
        case .loadConstant(let constant):
            s += 1
            setValue(constant, atIndex: s)
        case .loadValue(let memoryIndex):
            s += 1
            setValue(memory[memoryIndex], atIndex: s)
        case .add:
            memory[s - 1] += memory[s]
            s -= 1
        case .subtract:
            memory[s - 1] -= memory[s]
            s -= 1
        case .multiply:
            memory[s - 1] *= memory[s]
            s -= 1
        case .divide:
            memory[s - 1] /= memory[s]
            s -= 1
        case .invert:
            setValue(-memory[s], atIndex: s)
        case .and:
            if memory[s - 1] == 1 && memory[s] == 1 {
                setValue(1, atIndex: s - 1)
            } else {
                setValue(0, atIndex: s - 1)
            }
            s -= 1
        case .or:
            if memory[s - 1] == 1 || memory[s] == 1 {
                setValue(1, atIndex: s - 1)
            } else {
                setValue(0, atIndex: s - 1)
            }
            s -= 1
        case .negate:
            setValue(1 - memory[s], atIndex: s)
        case .compareLessThan:
            if memory[s - 1] < memory[s] {
                setValue(1, atIndex: s - 1)
            } else {
                setValue(0, atIndex: s - 1)
            }
            s -= 1
        case .compareGreaterThan:
            if memory[s - 1] > memory[s] {
                setValue(1, atIndex: s - 1)
            } else {
                setValue(0, atIndex: s - 1)
            }
            s -= 1
        case .compareEqual:
            if memory[s - 1] == memory[s] {
                setValue(1, atIndex: s - 1)
            } else {
                setValue(0, atIndex: s - 1)
            }
            s -= 1
        case .compareDifferent:
            if memory[s - 1] != memory[s] {
                setValue(1, atIndex: s - 1)
            } else {
                setValue(0, atIndex: s - 1)
            }
            s -= 1
        case .compareLessThanOrEqualTo:
            if memory[s - 1] <= memory[s] {
                setValue(1, atIndex: s - 1)
            } else {
                setValue(0, atIndex: s - 1)
            }
            s -= 1
        case .compareGreaterThanOrEqualTo:
            if memory[s - 1] >= memory[s] {
                setValue(1, atIndex: s - 1)
            } else {
                setValue(0, atIndex: s - 1)
            }
            s -= 1
        case .start: s = -1
        case .halt:
            finishHandler?()
            return
        case .assign(let memoryIndex):
            setValue(memory[s], atIndex: memoryIndex)
            s -= 1
        case .jump(let label):
            guard let instructionIndex = labelMap[label] else { throw RuntimeError(message: String(format: NSLocalizedString("Internal error: label %@ was being accessed but was never declared.", comment: ""), label)) }
            nextInstructionIndex = instructionIndex
        case .jumpIfFalse(let label):
            if memory[s] == 0 {
                guard let instructionIndex = labelMap[label] else { throw RuntimeError(message: String(format: NSLocalizedString("Internal error: label %@ was being accessed but was never declared.", comment: ""), label)) }
                nextInstructionIndex = instructionIndex
            }
            s -= 1
        case .null: break // No-op
        case .read:
            s += 1
            readHandler?()
            return
        case .print:
            printHandler?(memory[s])
            s -= 1
        case .alloc(let memoryHead, let length):
            for k in 0...(length - 1) {
                s += 1
                setValue(memory[safe: memoryHead + k] ?? 0, atIndex: s)
            }
        case .dealloc(let memoryHead, let length):
            for k in stride(from: length - 1, through: 0, by: -1) {
                setValue(memory[s], atIndex: memoryHead + k)
                s -= 1
            }
        case .call(let label):
            s += 1
            setValue(Decimal(i + 1), atIndex: s)
            nextInstructionIndex = labelMap[label]!
        case .return:
            nextInstructionIndex = Int(exactly: memory[s] as NSNumber)!
            s -= 1
        case .returnFunction(let memoryHead, let length):
            // Save the function value in an auxiliary variable
            let functionReturnValue = memory[s]
            s -= 1
            // Perform the same action as dealloc, if needed
            if let memoryHead = memoryHead, let length = length {
                for k in stride(from: length - 1, through: 0, by: -1) {
                    setValue(memory[s], atIndex: memoryHead + k)
                    s -= 1
                }
            }
            // Perform same action as return
            nextInstructionIndex = Int(exactly: memory[s] as NSNumber)!
            s -= 1
            // Perform same action as loadConstant(functionReturnValue), to put the function return value back into the top of the stack
            s += 1
            setValue(functionReturnValue, atIndex: s)
        }
        i = nextInstructionIndex
        try executeNextInstruction()
    }

    func setValueRead(_ valueRead: Decimal) {
        setValue(valueRead, atIndex: s)
        i += 1
        // TODO: Move this call away from here?
        try? executeNextInstruction()
    }

    // MARK: Convenience
    private func reset() {
        memory = []
        instructions = []
        s = 0
        i = 0
        labelMap = [:]
    }

    private func setValue(_ value: Decimal, atIndex index: Int) {
        if memory.indices.contains(index) {
            // It's already allocated, just assign
            memory[index] = value
        } else {
            // Memory is not allocated yet, let's do it now.
            // NOTE: This assumes we're simply appending a new value (i.e. the index is just 1 above the current indices), which's fine, given the current implementation.
            memory.append(value)
        }
    }
}
