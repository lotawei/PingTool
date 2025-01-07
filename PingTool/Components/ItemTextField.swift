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
    
    var body: some View {
        HStack {
            // 左侧图标（如果有）
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(isFocused ? .blue : .gray)
            }
            
            // 输入框
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
            RoundedRectangle(cornerRadius: 8)
                .stroke(isFocused ? Color.blue : Color.gray, lineWidth: 1)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white))
                .shadow(color: isFocused ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .animation(.easeInOut(duration: 0.3), value: isFocused)
        .padding(.horizontal)
    }
}
#Preview {
    @State  var  ip:String = "";
    return ItemTextField(
        text:$ip,
        placeholder: "请输入IP",
        icon: "",
        isSecure: false
    )
}
