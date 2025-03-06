import SwiftUI
import Combine

struct CommandlineTextView: View {
    @State private var text: String = ""
    
    // 接收数据的数组
    let data: [String]
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(text)
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                        .foregroundColor(.green)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .id("textBottom") // 添加ID用于滚动定位
                }
            }
            .background(
                ZStack {
                    Color.black
                    
                    // 添加网格线效果
                    VStack(spacing: 10) {
                        ForEach(0..<30, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.green.opacity(0.05))
                                .frame(height: 1)
                        }
                    }
                    
                    // 添加扫描线动画
                    ScanLineView()
                }
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
            .padding()
            // 监听 data 数组的变化
            .onReceive(Just(data)) { newData in
                text = newData.joined(separator: "\n") // 将 data 数组转换为字符串
                // 使用 DispatchQueue.main.async 确保在下一个渲染周期执行滚动
                DispatchQueue.main.async {
                    withAnimation {
                        proxy.scrollTo("textBottom", anchor: .bottom)
                    }
                }
            }
        }
    }
}

// 添加扫描线动画效果
struct ScanLineView: View {
    @State private var position: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.green.opacity(0),
                            Color.green.opacity(0.5),
                            Color.green.opacity(0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .offset(y: position)
                .opacity(0.7)
                .onAppear {
                    withAnimation(
                        Animation.linear(duration: 3.0)
                            .repeatForever(autoreverses: false)
                    ) {
                        position = geometry.size.height
                    }
                }
        }
    }
}