//
//  Utils.swift
//  iCrush
//
//  Created by Yery Castro on 16/7/24.
//

import SwiftUI

enum IconType: CaseIterable, Equatable {
    case empty
    case triangle
    case circle
    case square
    case heart
    case row
    case column
    case bang
    case bomb
    case gift
    
    var color: Color {
        switch self {
        case .empty:
                .clear
        case .triangle:
                .orange
        case .circle:
                .yellow
        case .square:
                .green
        case .heart:
                .blue
        case .row:
                .red
        case .column:
                .pink
        case .bang:
                .indigo
        case .bomb:
                .purple
        case .gift:
                .teal
        }
    }
    
    var name: String {
        switch self {
        case .empty:
            ""
        case .triangle:
            "triangle.fill"
        case .circle:
            "circle.fill"
        case .square:
            "square.fill"
        case .heart:
            "heart.fill"
        case .row:
            "arrowshape.left.arrowshape.right.fill"
        case .column:
            "arrow.up.arrow.down.circle"
        case .bang:
            "dot.radiowaves.left.and.right"
        case .bomb:
            "hazardsign.fill"
        case .gift:
            "ladybug.fill"
        }
    }
    
    static func random() -> IconType {
        let allCases = Self.allCases
        let randomIndex = Int.random(in: 1..<5)
        return allCases[randomIndex]
    }
    
    static func core() -> [IconType] {
        return [.circle, .triangle, .square, .heart]
    }
}


struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.bold()
            .scaleEffect(configuration.isPressed ? 1.3 : 1)
            .animation(.spring, value: configuration.isPressed)
    }
}
