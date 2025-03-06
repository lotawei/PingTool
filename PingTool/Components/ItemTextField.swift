//
//  ItemTextField.swift
//  PingTool
//
//  Created by work on 2025/1/3.
//

import Foundation
import SwiftUI

struct ItemTextField: View {
    @Binding var text: String
    var placeholder: String
    var icon: String? = nil
    var isSecure: Bool = false
    
    @FocusState private var isFocused: Bool
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(isFocused ? Color(hex: "#3498DB") : .gray)
                    .scaleEffect(isFocused ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFocused)
            }
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .focused($isFocused)
                    .disableAutocorrection(true)
            } else {
                TextField(placeholder, text: $text)
                    .focused($isFocused)
                    .disableAutocorrection(true)
            }
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.9),
                                Color.white.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        isFocused ? Color(hex: "#3498DB").opacity(0.8) : Color.gray.opacity(0.3),
                                        isFocused ? Color(hex: "#3498DB").opacity(0.4) : Color.gray.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: isFocused ? Color(hex: "#3498DB").opacity(0.2) : Color.black.opacity(0.1), radius: isFocused ? 8 : 4, x: 0, y: 2)
                
                // 玻璃拟态效果
                if isFocused {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .blur(radius: 3)
                        .mask(RoundedRectangle(cornerRadius: 12))
                }
            }
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .padding(.horizontal)
    }
}

#Preview {
     @State var ip: String = ""
    return ItemTextField(
        text: $ip,
        placeholder: "请输入IP",
        icon: "network",
        isSecure: false
    )
}
