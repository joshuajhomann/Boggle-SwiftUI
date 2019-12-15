//
//  BoggleModel.swift
//  Boggle-SwiftUI
//
//  Created by Joshua Homann on 12/13/19.
//  Copyright © 2019 raya. All rights reserved.
//

import Foundation
import Combine


struct Recognized: Identifiable {
  var id: String { word }
  var word: String
  var wasFound: Bool
}

class BoggleModel: ObservableObject {
  private var words = PrefixTree<String>()
  private var subscriptions = Set<AnyCancellable>()
  private var loadingSubscription: AnyCancellable?
  @Published var letters: [String] = []
  @Published var isLoaded = false
  @Published var lastRecognizedWord = "Boggle"
  @Published var allRecognizedWords: [Recognized] = []
  @Published var time = Constant.secondsOfGameTime
  @Published var isPlaying = true
  enum Constant {
    static let secondsOfGameTime = 60
    static let dimension = 4
    static let minimumWordLength = 3
    static let adjacentOffsets: [(Int, Int)] = (-1...1)
      .flatMap {y in (-1...1).map { x in (x,y)}}
      .filter {(x,y) in !(x == 0 && y == 0)}
    static let dice = [
      "AEANEG",
      "AHSPCO",
      "ASPFFK",
      "OBJOAB",
      "IOTMUC",
      "RYVDEL",
      "LREIXD",
      "EIUNES",
      "WNGEEH",
      "LNHNRZ",
      "TSTIYD",
      "OWTOAT",
      "ERTTYL",
      "TOESSI",
      "TERWHV",
      "NUIHMQ",
    ]
  }

  init() {
    loadingSubscription = Words
      .load(filter: { (Constant.minimumWordLength ..< Constant.dimension * Constant.dimension).contains($0.count) })
      .receive(on: RunLoop.main)
      .assertNoFailure()
      .sink(receiveValue: { [weak self] words in
        self?.words = words
        self?.isLoaded = true
        self?.reset()
      })
  }

  func validate(word: String) {
    if words.contains(word) {
      guard !allRecognizedWords.contains(where: { $0.word == word }) else {
        return lastRecognizedWord = "You already found \(word)"
      }
      lastRecognizedWord = word
      allRecognizedWords.append(.init(word: word, wasFound: true))
    } else {
      lastRecognizedWord = "\(word) is not a valid word"
    }
  }

  func reset() {
    letters = Constant
      .dice
      .compactMap { $0.randomElement().map(String.init)?.replacingOccurrences(of: "Q", with: "Qu") }
      .shuffled()
    time = Constant.secondsOfGameTime
    subscriptions.removeAll()

    let countDown = Timer
      .publish(every: 1, on: RunLoop.main, in: .default)
      .autoconnect()
      .map { _ in max(self.time - 1, 0) }

    countDown
      .assign(to: \.time, on: self)
      .store(in: &subscriptions)

    countDown
      .map { $0 != 0 }
      .assign(to: \.isPlaying, on: self)
      .store(in: &subscriptions)

    let solutions = makeSolutions()

    $isPlaying
      .filter({!$0})
      .map { [weak self] _ -> [Recognized] in
        guard let self = self else {
          return []
        }
        let allRecognizedWordsSet = Set(self.allRecognizedWords.map{$0.word})
        let missed = solutions.filter{!allRecognizedWordsSet.contains($0)}.sorted()
        return self.allRecognizedWords + missed.map { Recognized(word: $0, wasFound: false)}
      }
      .assign(to: \.allRecognizedWords, on: self)
      .store(in: &subscriptions)

    allRecognizedWords = []
    lastRecognizedWord = "Boggle"
  }

  private func makeSolutions() -> [String] {

    func adjacentWords(x: Int, y: Int, withPrefix prefix: String, excluding vistedIndices: Set<Int>) -> [String] {
      Constant
        .adjacentOffsets
        .compactMap { offset -> (Int, Int, Int)? in
          let (dx, dy) = offset
          let newX = x+dx
          let newY = y+dy
          guard (0..<Constant.dimension).contains(newX),
            (0..<Constant.dimension).contains(newY) else {
              return nil
          }
          let index = newX + newY * Constant.dimension
          guard !vistedIndices.contains(index) else {
            return nil
          }
          return (newX, newY, index)
      }
      .flatMap { combined -> [String] in
        let (x, y, index) = combined
        var newVistedIndices = vistedIndices
        newVistedIndices.insert(index)
        let newPrefix = prefix + self.letters[index].lowercased()
        guard self.words.contains(prefix: newPrefix) else {
          return []
        }
        if self.words.contains(newPrefix) {
          return [newPrefix] + adjacentWords(x: x, y: y, withPrefix: newPrefix, excluding: newVistedIndices)
        }
        return adjacentWords(x: x, y: y, withPrefix: newPrefix, excluding: newVistedIndices)
      }
    }

    let all = (0..<Constant.dimension).flatMap { y -> [String] in
      (0..<Constant.dimension).flatMap { x -> [String] in
        let index = x + y * Constant.dimension
        return adjacentWords(x: x, y: y, withPrefix: self.letters[index].lowercased(), excluding: .init([index]))
      }
    }
    return Array(Set(all)).sorted()
  }

}
