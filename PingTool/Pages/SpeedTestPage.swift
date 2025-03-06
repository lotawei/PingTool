//
//  SpeedTestPage.swift
//  PingTool
//
//  Created by work on 2024/12/30.
//

import SwiftUI
struct SpeedTestPage: View {
    
    @State private var currentValue: Double = 0 // 初始值
    @State var tool:PINGManagerTool =  PINGManagerTool()
    var body: some View {
        ItemCardContainer(content:{
            VStack {
                AnimatedGaugeView(value: $currentValue, maxValue: 30)
            }
            .onAppear{
                loadTestUrl()
            }
            .onDisappear{
                tool.cancelDownloadTask()
            }
            .removeBar()
        })}
}
extension  SpeedTestPage:NetSpeedResultHandler{
    func speedNet(speed: Double) {
        Logger.debug("\(speed)")
        currentValue = speed
    }
    
    func avgSpeed(avgspeed: Double) {
        Logger.debug("\(avgspeed)")
        currentValue = avgspeed
    }
    
    
    func loadTestUrl()  {
        guard let url = URL(string:"https://speedtest-co.turnkeyinternet.net/100mb.bin" ) else{
            Logger.debug("Url invalid")
            return
        }
        tool.startSpeedTest(from: url, duration: 10, updateSpeedHandler:self)
        
    }
    
}
