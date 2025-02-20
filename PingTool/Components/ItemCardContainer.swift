import SwiftUI

struct ItemCardContainer<Content: View>: View {
    @State private var isAnimated: Bool = true
    var cornerRadius: CGFloat
    var gradient: Gradient
    var blurRadius: CGFloat
    var content: () -> Content
    init(
        cornerRadius: CGFloat = 15,
        gradient: Gradient = Gradient(colors: [Color.orange.opacity(0.5), Color.red.opacity(0.5)]),
        blurRadius: CGFloat = 10,
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
                // 渐变背景
                LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(width: geometry.size.width * 1, height: geometry.size.height)
                    .cornerRadius(cornerRadius)
                    .overlay(
                        // 毛玻璃效果
                        Color.white.opacity(0.3)
                            .blur(radius: blurRadius)
                            .cornerRadius(cornerRadius)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                
                // 子视图内容
                content()
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(maxWidth: geometry.size.width)
        }
    }
}
