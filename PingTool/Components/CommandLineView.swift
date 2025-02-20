import SwiftUI
import Combine

struct CommandlineTextView: View {
    @State private var text: String = ""

    // 接收数据的数组
    let data: [String]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Text(text)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Scroll to bottom when text changes
                    .onChange(of: text) { _ in
                        proxy.scrollTo(text.count, anchor: .bottom)
                    }
            }
            .background(Color.black)
            .cornerRadius(12)
            .padding()
        }
        // 监听 data 数组的变化
        .onReceive(Just(data)) { newData in
            text = newData.joined(separator: "\n") // 将 data 数组转换为字符串
        }
    }
}
