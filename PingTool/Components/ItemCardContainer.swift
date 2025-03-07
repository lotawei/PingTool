import SwiftUI

struct ItemCardContainer<Content: View>: View {
    @State private var isHovered = false
    @State private var isAnimating = false
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
                        // 动态渐变背景
                        AngularGradient(gradient: gradient, center: .center)
                            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                            .frame(maxWidth: .infinity, maxHeight: .infinity) // 修改这里
                            .blur(radius: blurRadius)
                            .opacity(0.8)
                        
                        Color.white.opacity(0.12)
                            .background(Material.ultraThinMaterial)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .cornerRadius(cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                            )
                        
                        // 光效装饰
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .blur(radius: 25)
                            .offset(x: isAnimating ? 60 : -60, y: isAnimating ? -30 : 30)
                        
                        // 内容层
                        content()
                            .frame(maxWidth: .infinity, maxHeight: .infinity) // 修改这里
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // 修改这里
                    .cornerRadius(cornerRadius)
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 10)
                    .shadow(color: Color.white.opacity(0.15), radius: 15, x: 0, y: -10)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .scaleEffect(isHovered ? 1.02 : 1)
                    .rotation3DEffect(
                        .degrees(isHovered ? 2 : 0),
                        axis: (x: 0.5, y: 1.0, z: 0.0)
                    )
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isHovered)
                .onAppear {
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        isAnimating = true
                    }
                }
                .onHover { hovering in
                    isHovered = hovering
                }
            
    }
}
