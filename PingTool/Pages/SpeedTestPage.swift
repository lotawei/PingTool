//
//  SpeedTestPage.swift
//  PingTool
//
//  Created by work on 2024/12/30.
//

import SwiftUI
struct SpeedTestPage: View {
    @State private var currentValue: Double = 0 // 初始值
    var body: some View {
        VStack(spacing: 40) {
            AnimatedGaugeView(value: $currentValue, maxValue: 10)
            }
        .onAppear{
            loadTestUrl()
        }
            .padding()
    }
}
extension  SpeedTestPage{
    func loadTestUrl()  {
        guard let url = URL(string:"https://nbg1-speed.hetzner.com/100MB.bin" ) else{
            Logger.debug("Url invalid")
            return
        }
        PINGManagerTool.testDownloadSpeedWithLiveUpdate(from:url, duration: 5) { speed in
            currentValue = speed
        }
    }
}
