//
//  ContentView.swift
//  Boggle-SwiftUI
//
//  Created by Joshua Homann on 12/1/19.
//  Copyright © 2019 Joshua Homann. All rights reserved.
//

import SwiftUI

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

