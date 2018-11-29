//
//  SemanticAnalyzer.swift
//  virtual-machine-v2
//
//  Created by Roger Oba on 21/11/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import Foundation

final class SemanticAnalyzer {
    private var currentNode: Node!
    private var rootNode: Node!

    final class Node {
        var nodes: [Node] = []
        var returnsExplicitly = false
        let parent: Node?
        var elseNode: Node!
        var eventuallyReturns: Bool { return returnsExplicitly || elseNode?.validate() == true }

        init(parent: Node?) {
            self.parent = parent
        }

        func validate() -> Bool {
            if eventuallyReturns {
                return true
            } else {
                return nodes.isEmpty ? false : nodes.allSatisfy { $0.eventuallyReturns }
            }
        }
    }

    /// Initializes the components of the semantic analyzer.
    func startAnalyzing() {
        rootNode = Node(parent: nil)
        currentNode = rootNode
    }

    /// Execute when an `if` statement is found.
    func handleIfStatementFound() {
        let ifNode = Node(parent: currentNode)
        let elseNode = Node(parent: currentNode)
        // Assigning is not necessary if the current node returns explicitly.
        // But assigning is not allowed if the else node always returns, so we check if the current node always returns.
        if !currentNode.eventuallyReturns {
            currentNode.elseNode = elseNode
        }
        currentNode.nodes += [ ifNode, elseNode ]
        currentNode = ifNode
    }

    /// Execute when an `else` statement is found.
    func handleElseStatementFound() {
        currentNode = currentNode.elseNode
    }

    /// Execute when a branch scope is closed.
    func handleBranchClosing() {
        currentNode = currentNode.parent! // If we're in a branch, the parent node is never nil
    }

    /// Execute when a function return statement is found.
    func handleReturnStatementFound() {
        currentNode.returnsExplicitly = true
    }

    /// Determine whether the function analyzed always returns a value.
    ///
    /// - Returns: whether the root node validates.
    func validate() -> Bool {
        return rootNode.validate()
    }
}
