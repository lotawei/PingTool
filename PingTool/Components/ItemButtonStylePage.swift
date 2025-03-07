//
//  ItemButtonStylePage.swift
//  PingTool
//
//  Created by work on 2024/12/30.
//gpt: create a data model for github users endpoint

import SwiftUI
import Foundation
struct ItemButtonStylePage: View {
    let title: String
    let color: Color
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(color)
            .cornerRadius(10)
            .shadow(radius: 5)
    }
}

struct NavigationItem: Identifiable {
    let id = UUID() // 确保唯一性
    let title: String
    let color: Color
    let destination: AnyView
    
}
//自定义 link动画效果


struct AnimatedNavigationLink: View {
    let destination: AnyView
    let title: String
    let color: Color
    @State private var isPressed = false
    var body: some View {
        NavigationLink(destination: destination) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.clear)
                .frame(maxWidth: .infinity)
                .background(color)
                .cornerRadius(10)
                .shadow(radius: 5)
                .scaleEffect(isPressed ? 1.1 : 1.0) // Scale effect
                .opacity(isPressed ? 0.9 : 1.0)     // Opacity change
                .rotationEffect(isPressed ? .degrees(3) : .degrees(0)) // Slight rotation
                .animation(.easeInOut(duration: 0.2), value: isPressed) // Smooth animation
        }.buttonStyle(PlainButtonStyle())
    }
}

