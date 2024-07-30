//
//  GameButton.swift
//  iCrush
//
//  Created by Yery Castro on 16/7/24.
//

import SwiftUI

struct GameButton: View {
    let row: Int
    let col: Int
    let game: GameVM
    let geo: GeometryProxy
    
    var body: some View {
        Button {
            game.tryProcess(row: row, col: col)
        } label: {
            Rectangle()
                .frame(width: nil, height: geo.size.width)
                .foregroundStyle(Color(red: 242/255, green: 225/255, blue: 213/255))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    if game.board[row][col] != .empty {
                        Image(systemName: (game.board[row][col].name))
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(game.board[row][col].color)
                            .shadow(radius: 3)
                            .padding(4)
                    }
                }
        }
        .buttonStyle(CustomButtonStyle())
    }
}

//#Preview {
//    GameButton()
//}
