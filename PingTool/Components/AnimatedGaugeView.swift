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
                Circle()
                    .trim(from: 0.0, to: 0.75) // 显示四分之三的弧形
                    .stroke(
                        Color.gray.opacity(0.2),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135)) // 旋转至起始角度
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
            return (Color(hex: "#DC2430"), "Lost: 网络丢失或不可用")
        case 0.1..<5:
            return (Color(hex: "#7B4397"), "Low: 慢速网络")
        case 5..<7:
            return (Color(hex: "#005BEA"), "Medium: 中速网络")
        default:
            return (Color(hex: "#00C6FB"), "Fast: 快速网络")
        }
    }
}

struct PointerView: View {
    var value: Double
    var maxValue: Double

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let pointerLength = size.width * 0.5
            let normalizedValue = max(0, min(value, maxValue))
            let startAngle = 135.0
            let sweepAngle = 270.0
            let angle = Angle(degrees: startAngle + (normalizedValue / maxValue) * sweepAngle + 90)
            
            ZStack {
                // 指针阴影效果
                Rectangle()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 4, height: pointerLength)
                    .offset(y: -pointerLength / 2)
                    .rotationEffect(angle)
                    .blur(radius: 2)
                    .position(x: size.width / 2, y: size.height / 2)
                
                // 主指针
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.red.opacity(0.8), Color.red],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4, height: pointerLength)
                    .offset(y: -pointerLength / 2)
                    .rotationEffect(angle)
                    .position(x: size.width / 2, y: size.height / 2)

                // 金属质感箭头
                Path { path in
                    let triangleHeight: CGFloat = 15.0
                    let triangleWidth: CGFloat = 10.0

                    path.move(to: CGPoint(x: size.width / 2 - triangleWidth / 2, y: size.height / 2 - pointerLength))
                    path.addLine(to: CGPoint(x: size.width / 2 + triangleWidth / 2, y: size.height / 2 - pointerLength))
                    path.addLine(to: CGPoint(x: size.width / 2, y: size.height / 2 - pointerLength - triangleHeight))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color.red.opacity(0.9), Color.red],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 2)
                .rotationEffect(angle)
                .position(x: size.width / 2, y: size.height / 2)
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
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.6), color],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 6
                )
                .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 0)
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
