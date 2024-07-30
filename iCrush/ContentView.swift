//
//  ContentView.swift
//  iCrush
//
//  Created by Yery Castro on 16/7/24.
//

import SwiftUI

struct ContentView: View {
    var game = GameVM()
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack {
                    Console(game: game)
                    TimerView(game: game, geometry: geo)
                    GameGrid(game: game)
                    if game.combo != 0 {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            Text("Combo \(game.combo)!!")
                                .font(.largeTitle)
                                .bold()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("iCrush")
        }
    }
}

#Preview {
    ContentView()
}
