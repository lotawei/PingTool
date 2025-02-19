//
//  ContentView.swift
//  PingTool
//
//  Created by work on 2024/12/30.
//

import SwiftUI



struct MainAppIndexView: View {
    let items: [NavigationItem] = [
        NavigationItem(title: "Ip", color: .green, destination: AnyView(IpPage().overlay(ToastView()))),
        NavigationItem(title: "DNS", color: .red, destination: AnyView(DNSPage().overlay(ToastView()))),
        NavigationItem(title: "TraceRoute", color: .black, destination: AnyView(TraceRoute().overlay(ToastView()))),
        NavigationItem(title: "SpeedTest", color: .blue, destination: AnyView(SpeedTestPage().overlay(ToastView()))),
        NavigationItem(title: "WhoIpPage", color: .orange, destination: AnyView(WhoIPPage().overlay(ToastView()))),
        NavigationItem(title: "TrafficStatistics", color: .purple, destination: AnyView(TrafficStatisticsPage().overlay(ToastView()))),
        NavigationItem(title: "WebTestPing", color: .gray, destination: AnyView(WebTestPingPage().overlay(ToastView())))
    ]
    
    var body: some View {
        
        NavigationView {
            List(items) { item in
                AnimatedNavigationLink(destination: item.destination, title: item.title, color: item.color)
            }
            .listRowSeparator(.hidden) // 去除分割线
        }.padding(.zero).background(Color.white)
    }
}

#Preview {
    MainAppIndexView()
}
