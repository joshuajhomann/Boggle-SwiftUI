//
//  ContentView.swift
//  Boggle-SwiftUI
//
//  Created by Joshua Homann on 12/1/19.
//  Copyright © 2019 raya. All rights reserved.
//

import SwiftUI

struct LoadingView: View {
    @EnvironmentObject private var game: BoggleModel
    var body: some View {
        if game.isLoaded {
            BoardView().padding()
        } else {
            Text("Loading...").task { await game() }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView().environmentObject(BoggleModel())
    }
}

