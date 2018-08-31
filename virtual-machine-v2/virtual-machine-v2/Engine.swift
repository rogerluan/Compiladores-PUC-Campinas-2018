//
//  Engine.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 22/08/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation

final class Engine {
    static let shared = Engine()
    ///
    private var memory = Array<Decimal>(repeating: 0, count: 2048)
    /// Program counter
    private var pc: [Instruction] = []
    private var delay: TimeInterval = 1
    /// Memory index.
    private var s: Int = 0 { didSet { memoryChangedHandler?(memory) } }
    /// Program conter index.
    private var i: Int = 0 { didSet { programCounterChangedHandler?(i) } }
    private lazy var throttler = Throttler(minInterval: delay)

    var finishHandler: (() -> Void)? = nil
    var readHandler: (() -> Void)? = nil
    var printHandler: ((Decimal) -> Void)? = nil
    var memoryChangedHandler: (([Decimal]) -> Void)? = nil
    var programCounterChangedHandler: ((Int) -> Void)? = nil
    var valueRead: Decimal? = nil { didSet { handleValueRead() } }

    func process(text: String) -> [Instruction] {
        let lines: [String] = text.split(separator: "\n", omittingEmptySubsequences: true).map { String($0) }
        guard let instructions = lines.failableMap({ Instruction(rawInstruction: $0) }) else { return [] }
        return instructions
    }

    func execute(instructions: [Instruction]) {
        pc = instructions
        executeNextInstruction()
    }

    private func executeNextInstruction() {
        throttler.throttle {
            let nextInstruction = self.pc[self.i]
            self.execute(instruction: nextInstruction)
            self.i += 1
        }
    }

    private func execute(instruction: Instruction) {
        var nextInstructionIndex = i + 1
        switch instruction {
        case .loadConstant(let constant):
            s += 1
            memory[s] = constant
        case .loadValue(let memoryIndex):
            s += 1
            memory[s] = memory[memoryIndex]
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
            memory[s] = -memory[s]
        case .and:
            if memory[s - 1] == 1 && memory[s] == 1 {
                memory[s - 1] = 1
            } else {
                memory[s - 1] = 0
            }
            s -= 1
        case .or:
            if memory[s - 1] == 1 || memory[s] == 1 {
                memory[s - 1] = 1
            } else {
                memory[s - 1] = 0
            }
            s -= 1
        case .negate:
            memory[s] = 1 - memory[s]
        case .compareLesserThan:
            if memory[s - 1] < memory[s] {
                memory[s - 1] = 1
            } else {
                memory[s - 1] = 0
            }
            s -= 1
        case .compareGreaterThan:
            if memory[s - 1] > memory[s] {
                memory[s - 1] = 1
            } else {
                memory[s - 1] = 0
            }
            s -= 1
        case .compareEqual:
            if memory[s - 1] == memory[s] {
                memory[s - 1] = 1
            } else {
                memory[s - 1] = 0
            }
            s -= 1
        case .compareDifferent:
            if memory[s - 1] != memory[s] {
                memory[s - 1] = 1
            } else {
                memory[s - 1] = 0
            }
            s -= 1
        case .compareLesserThanOrEqualTo:
            if memory[s - 1] <=  memory[s] {
                memory[s - 1] = 1
            } else {
                memory[s - 1] = 0
            }
            s -= 1
        case .compareGreaterThanOrEqualTo:
            if memory[s - 1] >= memory[s] {
                memory[s - 1] = 1
            } else {
                memory[s - 1] = 0
            }
            s -= 1
        case .start: s = -1
        case .halt: finishHandler?()
        case .assign(let memoryIndex):
            memory[memoryIndex] = memory[s]
            s -= 1
        case .jump(let instructionIndex): nextInstructionIndex = instructionIndex
        case .jumpIfFalse(let instructionIndex):
            if memory[s] == 0 {
                nextInstructionIndex = instructionIndex
            }
            s -= 1
        case .null: break
        case .read:
            readHandler?()
            return
        case .print:
            printHandler?(memory[s])
            s -= 1
        case .alloc(let memoryHead, let length):
            for k in 0...(length - 1) {
                s += 1
                memory[s] = memory[memoryHead + k]
            }
        case .dealloc(let memoryHead, let length):
            for k in (length - 1)...0 {
                memory[s] = memory[memoryHead + k]
                s -= 1
            }
        case .call(let instructionIndex):
            s += 1
            memory[s] = Decimal(i + 1)
            nextInstructionIndex = instructionIndex
        case .return:
            nextInstructionIndex = Int(exactly: memory[s] as NSNumber)!
            s -= 1
        }
        i = nextInstructionIndex
        executeNextInstruction()
    }

    private func handleValueRead() {
        if let value = valueRead {
            s += 1
            memory[s] = value
        }
        valueRead = nil
        i += 1
        executeNextInstruction()
    }
}

extension Sequence {
    /// Returns an `Array` containing the results of mapping `transform` over `self`. Returns `nil` if `transform` returns `nil` at any point.
    func failableMap<T>(_ transform: (Element) throws -> T?) rethrows -> [T]? {
        var result: [T] = []
        for element in self {
            guard let transformedElement = try transform(element) else { return nil }
            result.append(transformedElement)
        }
        return result
    }
}
