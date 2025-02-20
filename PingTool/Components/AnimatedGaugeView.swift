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
                            gradient: Gradient(colors: [getNetworkInfo(for: value).color, getNetworkInfo(for: value).color]),
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
                    Text(String.init(format: "%.2f Kmpbs", value * 8))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(getNetworkInfo(for: value).color)
                    Text(getNetworkInfo(for: value).description)
                        .font(.headline)
                        .foregroundColor(Color.gray)
                }.padding(EdgeInsets(top: 130, leading: 0, bottom: 0, trailing: 0))
                //线条
                DynamicArcLines(radius: parent.size.width / 2.0, lineCount: 10)
            }
            .frame(width: parent.size.width, height: parent.size.height) // 仪表盘大小
        }
        
    }
    
    /// 根据网速值返回对应的颜色和描述
    func getNetworkInfo(for value: Double) -> (color: Color, description: String) {
        switch value {
        case ..<0.1:
            return (.red, "Lost: 网络丢失或不可用") // Lost
        case 0.1..<5:
            return (.yellow, "Low: 慢速网络") // Low
        case 5..<7:
            return (.green.opacity(0.6), "Medium: 中速网络") // Medium (Light Green)
        default:
            return (.green, "Fast: 快速网络") // Fast (Dark Green)
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
            let angle = Angle(degrees: startAngle + (normalizedValue / maxValue) * sweepAngle + 90) //补足 360 0.25
            

            ZStack {
                // 绘制指针
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 4, height: pointerLength)
                    .offset(y: -pointerLength / 2) // 从中心点向外延伸
                    .rotationEffect(angle) // 应用动态计算的角度
                    .position(x: size.width / 2, y: size.height / 2) // 设置指针中心位置

                // 绘制三角形箭头
                Path { path in
                    let triangleHeight: CGFloat = 15.0 // 三角形高度
                    let triangleWidth: CGFloat = 10.0  // 三角形宽度

                    path.move(to: CGPoint(x: size.width / 2 - triangleWidth / 2, y: size.height / 2 - pointerLength)) // 左下角
                    path.addLine(to: CGPoint(x: size.width / 2 + triangleWidth / 2, y: size.height / 2 - pointerLength)) // 右下角
                    path.addLine(to: CGPoint(x: size.width / 2, y: size.height / 2 - pointerLength - triangleHeight)) // 顶点
                    path.closeSubpath() // 关闭路径，形成三角形
                }
                .fill(Color.red)
                .rotationEffect(angle) // 旋转三角形与指针同步
                .position(x: size.width / 2, y: size.height / 2) // 设置箭头的位置
            }
        }
    }
}


class AnimationTimer: ObservableObject {
    private var timer: Timer?
    @Published var randomLengths: [CGFloat] = []
    @Published var randomColors: [Color] = []
    var lineCount: Int
    var radius: CGFloat

    init(lineCount: Int, radius: CGFloat) {
        self.lineCount = lineCount
        self.radius = radius
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            self.randomLengths = (0..<self.lineCount).map { _ in CGFloat.random(in: self.radius * 0.3...self.radius * 0.8) }
            self.randomColors = (0..<self.lineCount).map { _ in self.getRandomColor() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func getRandomColor() -> Color {
        Color(hue: Double.random(in: 0...1), saturation: 0.8, brightness: 0.9)
    }
}

struct  ContentV:  View{
    @State private var maxValue: Double = 10 // 初始值
    @State private var currentValue: Double = 0.5 // 初始值
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
    @StateObject private var animationTimer: AnimationTimer
    init(radius: CGFloat, lineCount: Int) {
        self.radius = radius
        self.lineCount = lineCount
        _animationTimer = StateObject(wrappedValue: AnimationTimer(lineCount: lineCount, radius: radius))
    }
//    init(radius: CGFloat, lineCount: Int) {
//        _animationTimer = StateObject(wrappedValue: AnimationTimer(lineCount: lineCount, radius: radius))
//    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let angleStep = 270.0 / Double(lineCount)
            
            ForEach(0..<lineCount, id: \.self) { index in
                let angle = Angle(degrees: 135 + angleStep * Double(index))
                let startRadius: CGFloat = radius * 0.8
                let length = animationTimer.randomLengths.indices.contains(index) ? animationTimer.randomLengths[index] : startRadius
                let color = animationTimer.randomColors.indices.contains(index) ? animationTimer.randomColors[index] : Color.white
                
                let x1 = center.x + startRadius * CGFloat(cos(angle.radians))
                let y1 = center.y + startRadius * CGFloat(sin(angle.radians))
                let x2 = center.x + length * CGFloat(cos(angle.radians))
                let y2 = center.y + length * CGFloat(sin(angle.radians))

                Path { path in
                    path.move(to: CGPoint(x: x1, y: y1))
                    path.addLine(to: CGPoint(x: x2, y: y2))
                }
                .stroke(color, lineWidth: 6)
            }
        }
        .onAppear {
            animationTimer.start()
        }
        .onDisappear {
            animationTimer.stop()
        }
    }
}
#Preview {
    
    ContentV()
    
}
