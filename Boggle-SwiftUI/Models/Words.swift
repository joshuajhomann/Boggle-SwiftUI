//
//  Words.swift
//  Boggle-SwiftUI
//
//  Created by Joshua Homann on 12/13/19.
//

import Foundation
import Combine
import UIKit

enum Words {
    enum Error: Swift.Error {
        case invalidURL
    }
    static func load(filter predicate: @escaping (String) -> Bool) async throws -> PrefixTree<String> {
        try await Task<PrefixTree<String>, Swift.Error>(priority: .high) {
            guard let json = Bundle.main.url(forResource: "words" as String, withExtension: "json") else {
                throw Error.invalidURL
            }
            let words = try JSONDecoder().decode([String].self, from: try Data(contentsOf: json))
            return PrefixTree<String>(elements: words.filter(predicate))
        }.value
    }
}
