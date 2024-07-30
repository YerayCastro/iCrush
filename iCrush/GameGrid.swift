//
//  GameGrid.swift
//  iCrush
//
//  Created by Yery Castro on 16/7/24.
//

import SwiftUI

struct GameGrid: View {
    var game: GameVM
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(spacing: 4), count: 8), spacing: 4) {
            ForEach(0..<game.rows) { row in
                ForEach(0..<game.columns) { col in
                    GeometryReader { geo in
                        GameButton(row: row, col: col, game: game, geo: geo)
                    }
                    .aspectRatio(contentMode: .fit)
                }
            }
        }
        .padding(12)
        .background(.purple)
        
        if !game.isPlaying {
            Button {
                game.gameStart()
            } label: {
                Text("Game Start")
                    .font(.largeTitle)
                    .padding()
                    .foregroundStyle(.white)
                    .background(.purple)
                
            }
        }
    }
}

#Preview {
    GameGrid(game: GameVM())
}
