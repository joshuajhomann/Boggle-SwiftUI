//
//  Words.swift
//  Boggle-SwiftUI
//
//  Created by Joshua Homann on 12/13/19.
//  Copyright © 2019 raya. All rights reserved.
//

import Foundation
import Combine
import UIKit

enum Words {
  enum Error: Swift.Error {
    case invalidURL
  }
  static func load(filter: @escaping (String) -> Bool) -> Future<PrefixTree<String>, Swift.Error> {
    .init { promise in
      DispatchQueue.global(qos: .userInteractive).async {
        guard let json = Bundle.main.url(forResource: "words" as String?, withExtension: "json") else {
          return promise(.failure(Error.invalidURL))
        }
        switch (Result {
          try JSONDecoder().decode([String].self, from: try Data(contentsOf: json))
        }) {
        case .success(let words):
          promise(.success(PrefixTree<String>(elements: words.filter(filter))))
        case .failure(let error):
          promise(.failure(error))
        }
      }
    }
  }
}
