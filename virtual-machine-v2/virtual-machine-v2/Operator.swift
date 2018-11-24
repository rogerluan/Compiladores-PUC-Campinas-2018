//
//  Operator.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 23/11/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation

enum Operator : CustomStringConvertible, Comparable {
    static func < (lhs: Operator, rhs: Operator) -> Bool {
        return lhs.precedence.rawValue < rhs.precedence.rawValue
    }

    case unaryPlus, unaryMinus, not
    case multiplication, division
    case sum, subtraction
    case greater, lesser, greaterThanOrEqualTo, lesserThanOrEqualTo, equal, different
    case and
    case or

    var precedence: PrecedenceGroup {
        switch self {
        case .unaryPlus, .unaryMinus, .not: return .unary
        case .multiplication, .division: return .multiplication
        case .sum, .subtraction: return .sum
        case .greater, .lesser, .greaterThanOrEqualTo, .lesserThanOrEqualTo, .equal, .different: return .comparison
        case .and: return .and
        case .or: return .or
        }
    }

    var description: String {
        switch self {
        case .unaryPlus: return " u+"
        case .unaryMinus: return " u-"
        case .not: return " !"
        case .multiplication: return " * "
        case .division: return " / "
        case .sum: return " + "
        case .subtraction: return " - "
        case .greater: return " > "
        case .lesser: return " < "
        case .greaterThanOrEqualTo: return " >= "
        case .lesserThanOrEqualTo: return " <= "
        case .equal: return " == "
        case .different: return " != "
        case .and: return " && "
        case .or: return " | "
        }
    }
}

enum PrecedenceGroup : Int {
    case unary = 200
    case multiplication = 180
    case sum = 160
    case comparison = 140
    case and = 120
    case or = 100
}
