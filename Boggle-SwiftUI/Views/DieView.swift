//
//  DieView.swift
//  Boggle-SwiftUI
//
//  Created by Joshua Homann on 12/17/19.
//  Copyright © 2019 Joshua Homann. All rights reserved.
//

import SwiftUI

struct DieView: View {
  var letter: String
  var isHighlighted: Bool
  var isDisabled: Bool
  var body: some View {
    ZStack {
      Rectangle()
        .fill(color())
        .animation(.easeInOut)
        .cornerRadius(16)
        .shadow(color: Color.black, radius: 2, x: 2, y: 2)
      Text(letter)
        .fontWeight(.black)
        .font(.largeTitle)
    }
  }
  private func color() -> Color {
    if isDisabled {
      return .gray
    } else if isHighlighted {
      return .yellow
    }
    return .init(white: 0.95)
  }
}
