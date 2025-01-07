//
//  ItemText.swift
//  PingTool
//
//  Created by work on 2025/1/6.
//

import Foundation
import SwiftUI
// 自定义字体样式
extension Text {
    func itemLarge() -> some View {
        self.font(.custom("Open Sans", size: 20)) // 标题字体
            .foregroundColor(Color(hex: "#FFFFFF"))
            .bold()
    }
    
    func itemMedium() -> some View {
        self.font(.custom("Open Sans", size: 14)) // 子标题字体
            .foregroundColor(Color(hex: "#2C3E50"))
    }
    
    func itemSmall() -> some View {
        self.font(.custom("Roboto", size: 9)) // 正文字体
            .foregroundColor(Color(hex: "#34495E"))
    }
}

// 扩展 Color 支持 16 进制颜色
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        r = Double((int >> 16) & 0xFF) / 255.0
        g = Double((int >> 8) & 0xFF) / 255.0
        b = Double(int & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
