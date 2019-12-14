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
      .load()
      .receive(on: RunLoop.main)
      .assertNoFailure()
      .sink(receiveValue: { [weak self] words in
        self?.words = words
        self?.isLoaded = true
      })

    reset()
  }

  func validate(word: String) {
    if words.contains(word) {
      guard !allRecognizedWords.contains(where: { $0.word == word }) else {
        return lastRecognizedWord = "You already found \(word)"
      }
      lastRecognizedWord = word
      allRecognizedWords.append(.init(word: word))
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

  }
}
