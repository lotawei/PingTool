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
            Color(hex: "FF6B6B").opacity(0.8),
            Color(hex: "4ECDC4").opacity(0.8),
            Color(hex: "45B7D1").opacity(0.8)
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
                    .frame(width: geometry.size.width, height: geometry.size.height )
                    .blur(radius: blurRadius)
                    .opacity(0.8)
                
//                // 玻璃效果背景
                Color.white.opacity(0.15)
                    .background(Material.ultraThinMaterial)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .cornerRadius(cornerRadius)
                
                // 光效装饰
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                    .offset(x: isAnimating ? 50 : -50, y: isAnimating ? -25 : 25)
//                
                // 内容层
                content()
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(maxWidth: geometry.size.width,maxHeight: geometry.size.height)
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
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isHovered)
            .onAppear {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
            .onHover { hovering in
                isHovered = hovering
            }
        }
    }
}
