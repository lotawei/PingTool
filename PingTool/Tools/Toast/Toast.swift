//
//  Toast.swift
//  demopackage
//
//  Created by work on 2024/12/18.
//

import Foundation
import SwiftUI

enum ToastType {
    case success
    case error
    case warning
}

struct Toast: View {
    var message: String
    var type: ToastType
    
    var body: some View {
        Text(message)
            .padding()
            .foregroundColor(.white)
            .background(backgroundColor)
            .cornerRadius(10)
            .shadow(radius: 10)
    }
    
    // 根据 Toast 类型设置背景颜色
    private var backgroundColor: Color {
        switch type {
        case .success:
            return Color.green.opacity(0.8)
        case .error:
            return Color.red.opacity(0.8)
        case .warning:
            return Color.orange.opacity(0.8)
        }
    }
}

class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var message: String = ""
    @Published var type: ToastType = .success
    @Published var isShowing: Bool = false
    
    private init() {}
    
    // 显示 Toast 方法
    func show(message: String, type: ToastType, duration: TimeInterval = 1.0) {
        self.message = message
        self.type = type
        withAnimation {
            self.isShowing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation {
                self.isShowing = false
            }
        }
    }
}
struct ToastView: View {
    @ObservedObject var toastManager = ToastManager.shared
    
    var body: some View {
        ZStack {
            if toastManager.isShowing {
                Toast(message: toastManager.message, type: toastManager.type)
                    .transition(.opacity) // 动画过渡
                    .zIndex(1) // 保证 Toast 位于最上层
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
