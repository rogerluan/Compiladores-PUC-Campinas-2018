//
//  Collection.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 21/11/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation

extension Collection {

    /// Splits the collection into an array of sub sequences of the given element,
    /// at the given predicate, as many times as possible.
    /// Similar to `split(maxSplits:omittingEmptySubsequences:isSeparator:)`, the
    /// main difference being that it doesn't exclude the separators from the final
    /// result.
    ///
    /// - Parameter isSeparator: A closure that takes an element as an argument and
    ///     returns a Boolean value indicating whether the collection should be
    ///     split at that element. It doesn't discard the separator elements from
    ///     the final result.
    /// - Returns: An array of subsequences, split from this collection's
    ///   elements.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the collection.
    func splitAt(isSeparator: (Iterator.Element) throws -> Bool) rethrows -> [SubSequence] {
        var p = self.startIndex
        var result:[SubSequence] = try self.indices.compactMap { i in
            guard try isSeparator(self[i]) else { return nil }
            defer { p = self.index(after: i) }
            return self[p...i]
        }
        if p != self.endIndex {
            result.append(suffix(from: p))
        }
        return result
    }
}
