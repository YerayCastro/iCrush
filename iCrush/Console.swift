//
//  Console.swift
//  iCrush
//
//  Created by Yery Castro on 29/7/24.
//

import SwiftUI

struct Console: View {
    var game: GameVM
    
    var body: some View {
        HStack(spacing: 8) {
            VStack {
                Text("Score")
                    .font(.title3)
                    .bold()
                Text("\(game.bestScore)")
                    .font(.title)
                    .bold()
                    .foregroundStyle(.white)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color.purple.gradient)
            
            VStack {
                Text("Best Score")
                    .font(.title2)
                    .bold()
                Text("\(game.score)")
                    .font(.title)
                    .bold()
                    .foregroundStyle(.white)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color.purple.gradient)

        }
    }
}

#Preview {
    Console(game: GameVM())
}
