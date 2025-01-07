//
//  File.swift
//  PingTool
//
//  Created by work on 2025/1/7.
//

import SwiftUI
struct AnimatedGaugeView: View {
   @Binding var value: Double // 当前网速值（Mbps）
    var maxValue: Double // 最大值（100+ Mbps）
    
    var body: some View {
        GeometryReader{ parent in
            ZStack {
                // 背景弧形
                Circle()
                    .trim(from: 0.0, to: 0.75) // 显示四分之三的弧形
                    .stroke(
                        Color.gray.opacity(0.2),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135)) // 旋转至起始角度
                
                // 前景弧形
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(value / maxValue, 1.0)) * 0.75)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [getColor(for: value), getColor(for: value)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))
                    .animation(.easeInOut(duration: 0.8), value: value)
                
                // 动态指针
                PointerView(value: value, maxValue: maxValue)
                // 中心文字显示
                VStack {
                    Text("\(Int(value)) Mbps")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(getColor(for: value))
                    Text(getDescription(for: value))
                        .font(.headline)
                        .foregroundColor(Color.gray)
                }.padding(EdgeInsets(top: 130, leading: 0, bottom: 0, trailing: 0))
                //线条
                DynamicArcLines(radius: parent.size.width / 2.0, lineCount: 20)
            }
            .frame(width: parent.size.width, height: parent.size.height) // 仪表盘大小
        }
        
    }
    
    /// 根据网速值返回对应的颜色
    func getColor(for value: Double) -> Color {
        switch value {
        case ..<0.01:
            return .red // Lost
        case 0.1..<5:
            return .yellow // Low
        case 5..<25:
            return .green.opacity(0.6) // Medium (Light Green)
        default:
            return .green // Fast (Dark Green)
        }
    }
    
    /// 根据网速值返回对应的描述
    func getDescription(for value: Double) -> String {
        switch value {
        case ..<0.1:
            return "Lost: 网络丢失或不可用"
        case 0.1..<5:
            return "Low: 慢速网络"
        case 5..<25:
            return "Medium: 中速网络"
        default:
            return "Fast: 快速网络"
        }
    }
}

struct PointerView: View {
    var value: Double
    var maxValue: Double

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let pointerLength = size.width * 0.5 // 指针长度
            
            // 修正后的角度计算
            let normalizedValue = max(0, min(value, maxValue)) // 确保 value 在 [0, maxValue] 范围内
            let startAngle = 135.0 // 起始角度
            let sweepAngle = 270.0 // 总角度范围
            let angle = Angle(degrees: startAngle + (normalizedValue / maxValue) * sweepAngle + 90)
            
            ZStack {
                // 绘制指针
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 4, height: pointerLength)
                    .offset(y: -pointerLength / 2) // 从中心点向外延伸
                    .rotationEffect(angle) // 应用动态计算的角度
                    .position(x: size.width / 2, y: size.height / 2) // 设置指针中心位置
                
                // 绘制箭头
                Path { path in
                      let arrowSize: CGFloat = 15.0
                       let arrowBaseWidth: CGFloat = 10.0

                       // 指向圆心的指针位置
                       path.move(to: CGPoint(x: size.width / 2, y: size.height / 2 - pointerLength))

                       // 左侧箭头
                       path.addLine(to: CGPoint(x: size.width / 2 - arrowBaseWidth / 2, y: size.height / 2 - pointerLength - arrowSize))

                       // 右侧箭头
                       path.addLine(to: CGPoint(x: size.width / 2 + arrowBaseWidth / 2, y: size.height / 2 - pointerLength - arrowSize))

                }
                .fill(Color.red)
                .rotationEffect(angle) // 箭头和指针一起旋转
                .position(x: size.width / 2, y: size.height / 2) // 设置箭头的位置
            }
        }
    }
}
struct  ContentV:  View{
    @State private var maxValue: Double = 1000 // 初始值
    @State private var currentValue: Double = 200 // 初始值
    var body: some View {
        VStack(spacing: 40) {
            AnimatedGaugeView(value: $currentValue, maxValue: maxValue)
            
            Slider(value: $currentValue, in: 0...maxValue)
                .padding()
                .accentColor(.blue)
        }
        .padding()
        
    }
}

struct DynamicArcLines: View {
    var radius: CGFloat // 半径
    var lineCount: Int // 线条数量
    @State private var randomLengths: [CGFloat] = [] // 动态线条长度
    @State private var randomColors: [Color] = [] // 动态颜色
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let angleStep = 270.0 / Double(lineCount) // 每个线条的角度间隔
            
            ForEach(0..<lineCount, id: \.self) { index in
                let angle = Angle(degrees: 135 + angleStep * Double(index))
                let startRadius: CGFloat = radius * 0.8// 起始半径
                let length = randomLengths.indices.contains(index) ? randomLengths[index] : startRadius
                let color = randomColors.indices.contains(index) ? randomColors[index] : Color.white
                
                // 计算线条起点和终点
                let x1 = center.x + startRadius * CGFloat(cos(angle.radians))
                let y1 = center.y + startRadius * CGFloat(sin(angle.radians))
                let x2 = center.x + length * CGFloat(cos(angle.radians))
                let y2 = center.y + length * CGFloat(sin(angle.radians))
                
                Path { path in
                    path.move(to: CGPoint(x: x1, y: y1))
                    path.addLine(to: CGPoint(x: x2, y: y2))
                }
                .stroke(color, lineWidth: 6) // 动态颜色
            }
        }
        .onAppear {
            // 初始化随机长度和颜色
            randomLengths = (0..<lineCount).map { _ in CGFloat.random(in: 0...radius) }
//            randomColors = (0..<lineCount).map { _ in getRandomColor() }
            startAnimation()
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                randomLengths = (0..<lineCount).map { _ in CGFloat.random(in: radius * 0.5...radius * 0.5) }
                randomColors = (0..<lineCount).map { _ in getRandomColor() }
            }
        }
    }
    
    private func getRandomColor() -> Color {
        Color(hue: Double.random(in: 0...1), saturation: 0.8, brightness: 0.9)
    }
}
#Preview {
    
    ContentV()
    
}
