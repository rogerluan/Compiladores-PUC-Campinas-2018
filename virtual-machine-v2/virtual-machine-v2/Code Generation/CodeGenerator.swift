//
//  Codeswift
//  virtual-machine-v2
//
//  Created by Roger Oba on 21/11/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation

final class CodeGenerator {
    /// The end result, consisting of an executable assembly-like file.
    var output: String = ""

    var instructions: [Instruction] { return Engine.shared.process(text: output) }

    var globalVariableCount = 0

    func generateInstruction(_ instruction: Instruction) {
        if instruction.hasNoArguments {
            output += instruction.opcode
        } else if instruction.hasStrictlyOneArgument {
            switch instruction {
            case .null(let label): output += "\(label) \(instruction.opcode)"
            default: output += "\(instruction.opcode) \(instruction.argument1!)"
            }

        } else if instruction.hasStrictlyTwoArguments {
            output += "\(instruction.opcode) \(instruction.argument1!) \(instruction.argument2!)"
        } else {
            fatalError()
        }
        output += "\n"
    }

    func generateInstructionsForPostFixedExpression(_ expression: [TokenType], symbolTable: SymbolTable) {
        for tokenType in expression {
            switch tokenType {
            case .leftParenthesis, .rightParenthesis: preconditionFailure()
            case .operator(let `operator`):
                switch `operator` {
                case .unaryPlus: break // No-op
                case .unaryMinus: generateInstruction(.invert)
                case .not: generateInstruction(.negate)
                case .multiplication: generateInstruction(.multiply)
                case .division: generateInstruction(.divide)
                case .sum: generateInstruction(.add)
                case .subtraction: generateInstruction(.subtract)
                case .greaterThan: generateInstruction(.compareGreaterThan)
                case .lessThan: generateInstruction(.compareLessThan)
                case .greaterThanOrEqualTo: generateInstruction(.compareGreaterThanOrEqualTo)
                case .lessThanOrEqualTo: generateInstruction(.compareLessThanOrEqualTo)
                case .equal: generateInstruction(.compareEqual)
                case .different: generateInstruction(.compareDifferent)
                case .and: generateInstruction(.and)
                case .or: generateInstruction(.or)
                }
            case .operand(let operand):
                switch operand.symbol {
                case .s_number: generateInstruction(.loadConstant(Int(operand.lexeme)!)) // Lexical and syntactic analysis guarantee this lexeme converts to a valid number
                case .s_identifier:
                    let entry = symbolTable.searchDeclaration(of: [ .variable, .function ], with: operand.lexeme, in: .global)
                    if let variableEntry = entry as? VariableEntry {
                        generateInstruction(.loadValue(memoryIndex: variableEntry.index))
                    } else if let functionEntry = entry as? FunctionEntry {
                        generateInstruction(.call(label: functionEntry.label))
                    } else {
                        preconditionFailure()
                    }
                case .s_true: generateInstruction(.loadConstant(1))
                case .s_false: generateInstruction(.loadConstant(0))
                default: preconditionFailure("There shouldn't be a non-operand here.")
                }
            }
        }
    }

    func reset() {
        output = ""
        globalVariableCount = 0
    }
}
