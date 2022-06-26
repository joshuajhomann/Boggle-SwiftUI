//
//  PrefixTree.swift
//  Boggle-SwiftUI
//
//  Created by Joshua Homann on 12/13/19.
//

import Foundation

final class PrefixTree<SomeCollection: RangeReplaceableCollection> where SomeCollection.Element: Hashable  {
    typealias Element = SomeCollection.Element
    typealias Node = PrefixTree<SomeCollection>
    private var children = [Element: PrefixTree]()
    private var isTerminal: Bool = false
    
    init(elements: [SomeCollection] = []) {
        self.children = [:]
        elements.forEach { self.insert($0) }
    }
    
    func insert(_ collection: SomeCollection) {
        terminalNode(for: collection, shouldInsert: true)?.isTerminal = true
    }
    
    func contains(_ collection: SomeCollection) -> Bool {
        terminalNode(for: collection)?.isTerminal == true
    }
    
    func contains(prefix: SomeCollection) -> Bool {
        terminalNode(for: prefix) != nil
    }
    
    private func terminalNode(for path: SomeCollection, shouldInsert: Bool = false) -> Node? {
        path.reduce(into: self as Node?) { node, element in
            if shouldInsert {
                let child = node?.children[element, default: Self()]
                node?.children[element] = child
            }
            node = node?.children[element]
        }
    }
}
