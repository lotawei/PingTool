import SwiftUI

struct ItemCardContainer<Content: View>: View {
    @State private var isHovered = false
    var cornerRadius: CGFloat
    var gradient: Gradient
    var blurRadius: CGFloat
    var content: () -> Content
    
    init(
        cornerRadius: CGFloat = 20,
        gradient: Gradient = Gradient(colors: [
            Color(hex: "1ABC9C").opacity(0.8),  // 清新的绿色
            Color(hex: "E74C3C").opacity(0.7),  // 活力的红色
            Color(hex: "F39C12").opacity(0.8),  // 温暖的橙色
        ]),
        blurRadius: CGFloat = 15,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.gradient = gradient
        self.blurRadius = blurRadius
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 优化的渐变背景
                LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .blur(radius: blurRadius)
                    .opacity(0.8)
                
                // 玻璃拟态效果
                Color.white.opacity(0.12)
                    .background(Material.ultraThinMaterial)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
                
                // 优化的光效装饰
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                    .offset(x: -30, y: 30)
                
                // 内容层
                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isHovered ? 1.02 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
        }
    }
}
