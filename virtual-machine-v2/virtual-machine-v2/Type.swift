//
//  Type.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 17/10/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation

/// The type of variables and function returns.
///
/// - Int: an integer type.
/// - Bool: a boolean type.
enum Type {
    case int, bool
}

extension Type : CustomStringConvertible {
    
    var description: String {
        switch self {
        case .int: return NSLocalizedString("Int", comment: "User-facing Type description. Should match with the term used to declare types in code.")
        case .bool: return NSLocalizedString("Bool", comment: "User-facing Type description. Should match with the term used to declare types in code.")
        }
    }
}
