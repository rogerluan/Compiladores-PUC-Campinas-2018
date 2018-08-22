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

    func process(text: String) -> [Instruction] {
        let lines: [String] = text.split(separator: "\n", omittingEmptySubsequences: true).map { String($0) }
        guard let instructions = lines.failableMap({ Instruction(rawInstruction: $0) }) else { return [] }
        return instructions
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
