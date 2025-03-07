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
        NavigationItem(title: "SpeedTest", color: .blue, destination: AnyView(SpeedTestPage().overlay(ToastView()))),
        NavigationItem(title: "WhoIpPage", color: .orange, destination: AnyView(WhoIPPage().overlay(ToastView()))),
        NavigationItem(title: "Ping", color: .gray, destination: AnyView(PingPage().overlay(ToastView())))
    ]
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 2)
    @State private var selectedItem: NavigationItem?
    @State private var isNavigating = false
    @Namespace private var animation
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(items) { item in
                        CardView(item: item, namespace: animation)
                            .matchedGeometryEffect(id: item.id, in: animation)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    selectedItem = item
                                    isNavigating = true
                                }
                            }
                    }
                }
                .padding(20)
            }
            .navigationTitle("NetWorkTool")
            .background(Color.white)
            .background(
                NavigationLink(destination: selectedItem?.destination,
                             isActive: $isNavigating) { EmptyView() }
            )
            
        }
    }
    
    struct CardView: View {
        let item: NavigationItem
        let namespace: Namespace.ID
        @State private var isHovered = false
        
        var body: some View {
            VStack(spacing: 15) {
                Image(systemName: iconName(for: item.title))
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .background(
                        Circle()
                            .fill(item.color.opacity(0.2))
                    )
                    .overlay(
                        Circle()
                            .stroke(item.color, lineWidth: 2)
                            .scaleEffect(isHovered ? 1.1 : 1.0)
                    )
                
                Text(item.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white,
                                item.color.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: item.color.opacity(0.2), radius: 10, x: 0, y: 5)
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
        }
        
        private func iconName(for title: String) -> String {
            switch title {
            case "Ip": return "network"
            case "DNS": return "server.rack"
            case "SpeedTest": return "speedometer"
            case "WhoIpPage": return "globe"
            case "Ping": return "antenna.radiowaves.left.and.right"
            default: return "questionmark.circle"
            }
        }
    }
}
    #Preview {
    MainAppIndexView()
}
