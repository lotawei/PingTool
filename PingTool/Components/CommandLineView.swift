import SwiftUI
import Combine
// 命令行窗口模拟
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
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .id("textBottom") // 添加ID用于滚动定位
                }
            }
            .background(
                ZStack {
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
            .onReceive(Just(data)) { newData in
                text = newData.joined(separator: "\n") // 将 data 数组转换为字符串
                
                // 仅为滚动操作添加动画
                DispatchQueue.main.async {
                    withAnimation {
                        // 滚动到 "textBottom" ID，确保滚动到最新的位置
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
                    withAnimation{
                        position = geometry.size.height
                    }
                }
        }
    }
}

// 预览
struct CommandlineTextView_Previews: PreviewProvider {
    static var previews: some View {
        CommandlineTextView(data: ["$ ping 8.8.8.8", "64 bytes from 8.8.8.8: icmp_seq=1 ttl=116 time=36.6 ms", "64 bytes from 8.8.8.8: icmp_seq=2 ttl=116 time=35.9 ms", "64 bytes from 8.8.8.8: icmp_seq=3 ttl=116 time=37.2 ms"])
            .preferredColorScheme(.dark)
    }
}
