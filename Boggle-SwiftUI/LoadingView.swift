//
//  ContentView.swift
//  Boggle-SwiftUI
//
//  Created by Joshua Homann on 12/1/19.
//  Copyright © 2019 raya. All rights reserved.
//

import SwiftUI
import Combine

struct BoardView: View {
  @EnvironmentObject var game: BoggleModel
  @State private var squareSize: CGFloat = 0
  @State private var squares: [CGRect] = []
  @State private var selectedIndices: [Int] = []
  private var dragState: CurrentValueSubject<DragState, Never> = .init(.notDragging)
  private enum DragState {
    case dragging, failed, notDragging
  }
  private enum Constant {
    static let boardMargin: CGFloat = 12
    static let squareSpacing: CGFloat = 8
    static let fontThreshold: CGFloat = 36
    static let inset: CGFloat = 20
  }

  private static func index(x: Int, y: Int) -> Int {
    BoggleModel.Constant.dimension * y + x
  }

  private func timerColor() -> Color {
    switch self.game.time {
    case 0..<20:
      return Color.red
    case 20..<40:
      return Color.yellow
    default:
      return Color.green
    }
  }

  var body: some View {
    VStack {
      VStack {
        HStack {
          Text(self.game.isPlaying ? String(describing: self.game.time) : "Game Over").foregroundColor(self.timerColor())
          Spacer()
          Button("Reset", action: { self.game.reset() })
        }
        Text(self.game.lastRecognizedWord).padding()
      }
      .font(.largeTitle)
      .padding()
      GeometryReader { geometry in
        VStack(spacing: Constant.squareSpacing) {
          ForEach (0..<BoggleModel.Constant.dimension) { y in
            HStack(spacing: Constant.squareSpacing) {
              ForEach (0..<BoggleModel.Constant.dimension) { x in
                DieView(
                  letter: self.game.letters[Self.index(x: x, y: y)],
                  isHighlighted: self.selectedIndices.contains(Self.index(x: x, y: y)),
                  isDisabled: !self.game.isPlaying
                )
                .frame(width: self.squareSize, height: self.squareSize)
              }
            }
          }
        }.sideEffect {
          let geometry = geometry.frame(in: .local).size
          let minimumDimension = min(geometry.width, geometry.height)
          let dimension = CGFloat(BoggleModel.Constant.dimension)
          let squareSize = (minimumDimension -  dimension * Constant.squareSpacing) / dimension
          DispatchQueue.main.async {
            self.squareSize = squareSize
            let size = CGSize(width: squareSize, height: squareSize)
            self.squares = (0..<BoggleModel.Constant.dimension).flatMap { y in
              (0..<BoggleModel.Constant.dimension).map { x in
                CGRect(
                  origin: .init(
                    x: (squareSize + Constant.squareSpacing) * CGFloat(x),
                    y: (squareSize + Constant.squareSpacing) * CGFloat(y)
                  ),
                  size:size
                ).insetBy(dx: Constant.inset, dy: Constant.inset)
              }
            }
          }
        }.gesture(DragGesture()
          .onChanged { value in
            guard self.game.isPlaying else {
              return
            }
            let point = value.location
            guard self.dragState.value != .failed,
              let index = self.squares.firstIndex(where: { $0.contains(point)}) else {
                return
            }
            guard !self.selectedIndices.contains(index) else {
              if index != self.selectedIndices.last {
                self.selectedIndices.removeAll()
                self.dragState.value = .failed
              }
              return
            }
            self.selectedIndices.append(index)
        }.onEnded { value in
          guard self.game.isPlaying else {
            return
          }
          defer {
            self.selectedIndices.removeAll()
          }
          guard self.selectedIndices.count >= BoggleModel.Constant.minimumWordLength else {
            return
          }
          let word = self.selectedIndices
            .map { self.game.letters[$0] }
            .reduce(into: "") { $0 = $0 + $1 }
            .lowercased()
          self.game.validate(word: word)
          }
        )
      }
      List {
        ForEach(self.game.allRecognizedWords) { recognized in
          Text(recognized.word)
            .foregroundColor(recognized.wasFound ? Color.green : Color.red)
            .font(.largeTitle)
        }
      }
    }
  }
}

struct DieView: View {
  var letter: String
  var isHighlighted: Bool
  var isDisabled: Bool
  var body: some View {
    ZStack {
      Rectangle()
        .fill(color())
        .cornerRadius(16)
        .shadow(color: Color.black, radius: 2, x: 2, y: 2)
      Text(letter)
        .fontWeight(.black)
        .font(.largeTitle)
    }
  }
  private func color() -> Color {
    if isDisabled {
      return Color.gray
    } else if isHighlighted {
      return Color.yellow
    }
    return  Color(white: 0.95)
  }
}

struct LoadingView: View {
  @EnvironmentObject var game: BoggleModel
  @State var dimension: CGFloat = 0
  var body: some View {
    game.isLoaded
      ? AnyView(BoardView().padding())
      : AnyView(Text("Loading..."))
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    LoadingView().environmentObject(BoggleModel())
  }
}

extension View {
  func sideEffect(_ sideEffect: @escaping () -> Void) -> some View {
    sideEffect()
    return self
  }
}
