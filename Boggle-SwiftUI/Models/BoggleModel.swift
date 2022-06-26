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

@MainActor
final class BoggleModel: ObservableObject {
    private var words = PrefixTree<String>()
    private var subscriptions = Set<AnyCancellable>()
    @Published var letters: [String] = []
    @Published var isLoaded = false
    @Published var lastRecognizedWord = "Boggle"
    @Published var allRecognizedWords: [Recognized] = []
    @Published var time = Constant.secondsOfGameTime
    @Published var isPlaying = true
    @Published var selectedIndices: [Int] = []
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
        static let adjacentIndices: [[Int]] = {
            let adjacentOffsets: [(Int, Int)] = (-1...1)
                .flatMap {y in (-1...1).map { x in (x,y)}}
                .filter {(x,y) in !(x == 0 && y == 0)}
            return (0..<dimension*dimension)
                .map { index in
                    adjacentOffsets
                        .compactMap { (dx, dy) in
                            let x = (index % dimension)+dx
                            let y = (index / dimension)+dy
                            guard (0..<Constant.dimension).contains(x),
                                  (0..<Constant.dimension).contains(y) else {
                                return nil
                            }
                            return x+y*dimension
                        }
                }
        }()
    }
    
    func callAsFunction() async {
        words = try! await Words.load(filter: {(Constant.minimumWordLength ..< Constant.dimension * Constant.dimension).contains($0.count)})
        isLoaded = true
        reset()
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
            .share()
        
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
                let missed = solutions.filter{!allRecognizedWordsSet.contains($0)}
                return self.allRecognizedWords + missed.map { Recognized(word: $0, wasFound: false)}
            }
            .assign(to: \.allRecognizedWords, on: self)
            .store(in: &subscriptions)
        
        allRecognizedWords = []
        lastRecognizedWord = "Boggle"
    }
    
    func selectLetter(at index: Int) -> Bool {
        guard isPlaying else {
            return false
        }
        guard !selectedIndices.contains(index) else {
            if index == self.selectedIndices.last {
                return true
            }
            selectedIndices.removeAll()
            return false
        }
        selectedIndices.append(index)
        return true
    }
    
    func finishSelection() {
        guard isPlaying else { return }
        defer { selectedIndices.removeAll() }
        guard self.selectedIndices.count >= Constant.minimumWordLength else { return }
        let word = selectedIndices
            .map { self.letters[$0] }
            .reduce(into: "") { $0 = $0 + $1 }
            .lowercased()
        validate(word: word)
    }
    
    private func makeSolutions() -> [String] {
        func adjacentWords(index: Int, withPrefix prefix: String, excluding visitedIndices: Set<Int>) -> [String] {
            Constant
                .adjacentIndices[index]
                .flatMap { index -> [String] in
                    guard !visitedIndices.contains(index) else { return [] }
                    let newPrefix = prefix + letters[index].lowercased()
                    guard self.words.contains(prefix: newPrefix) else { return [] }
                    var newVisitedIndices = visitedIndices
                    newVisitedIndices.insert(index)
                    return self.words.contains(newPrefix)
                    ? [newPrefix] + adjacentWords(index: index, withPrefix: newPrefix, excluding: newVisitedIndices)
                    : adjacentWords(index: index, withPrefix: newPrefix, excluding: newVisitedIndices)
                }
        }
        
        return Array(Set(
            (0..<Constant.dimension * Constant.dimension).flatMap {
                adjacentWords(index: $0, withPrefix: letters[$0].lowercased(), excluding: .init([$0]))
            }.sorted()
        ))
    }
    
}
