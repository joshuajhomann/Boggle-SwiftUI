//
//  BoardView.swift
//  Boggle-SwiftUI
//
//  Created by Joshua Homann on 12/17/19.
//  Copyright © 2019 raya. All rights reserved.
//

import SwiftUI
import Combine

struct BoardView: View {
    @EnvironmentObject var game: BoggleModel
    @State private var squareSize: CGFloat = 0
    @State private var squares: [CGRect] = []
    private var dragState: CurrentValueSubject<DragState, Never> = .init(.notDragging)
    private enum DragState {
        case dragging, failed, notDragging
    }
    private enum Constant {
        static let boardMargin: CGFloat = 12
        static let squareSpacing: CGFloat = 16
        static let fontThreshold: CGFloat = 36
        static let inset: CGFloat = 20
    }
    
    private static func index(x: Int, y: Int) -> Int {
        BoggleModel.Constant.dimension * y + x
    }
    
    private func timerColor() -> Color {
        switch self.game.time {
        case 0..<20:
            return .red
        case 20..<40:
            return .yellow
        default:
            return .green
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
                Text(game.lastRecognizedWord).padding()
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
                                    isHighlighted: self.game.selectedIndices.contains(Self.index(x: x, y: y)),
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
                }
                .gesture(DragGesture()
                    .onChanged { value in
                        let point = value.location
                        guard dragState.value != .failed,
                              let index = self.squares.firstIndex(where: { $0.contains(point)}) else {
                            return
                        }
                        dragState.value = self.game.selectLetter(at: index) ? .dragging : .failed
                    }.onEnded { value in
                        game.finishSelection()
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
