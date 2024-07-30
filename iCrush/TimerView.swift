//
//  TimerView.swift
//  iCrush
//
//  Created by Yery Castro on 29/7/24.
//

import SwiftUI

struct TimerView: View {
    var game: GameVM
    var geometry: GeometryProxy
    
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .frame(height: 41)
            
            Capsule()
                .foregroundStyle(Color.purple.gradient)
                .frame(maxWidth: (geometry.size.width - 32) * CGFloat(Double(game.gameTime) / (10 + Double(game.gameTime))))
                .frame(height: 40)
                .overlay(alignment: .trailing) {
                    
                    Text("\(game.gameTime)")
                        .font(.title)
                        .bold()
                        .foregroundStyle(.white)
                        .padding(.trailing, 4)
                    
                }
        }
    }
}

//#Preview {
//    TimerView()
//}
