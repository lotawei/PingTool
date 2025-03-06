//
//  IpPage.swift
//  PingTool
//
//  Created by work on 2024/12/30.
//

import Foundation
import SwiftUI
struct DNSPage: View {
    @State private var dnsServers: [String] = []
    @State private var isRefreshing = false
    
    fileprivate func fetchDNSProcess() {
        withAnimation {
            isRefreshing = true
        }
        
        PINGManagerTool.fetchDNSServers(completion: { servers in
            DispatchQueue.main.async {
                if servers.isEmpty {
                    ToastManager.shared.show(message: "DNS服务器获取失败", type: .error)
                } else {
                    self.dnsServers = servers
                }
                
                withAnimation {
                    isRefreshing = false
                }
            }
        })
    }
    
    var body: some View {
        ItemCardContainer(content: {
            VStack(spacing: 20) {
                // 刷新按钮
                Button(action: fetchDNSProcess) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(isRefreshing ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                }
                
                // DNS服务器信息卡片
                LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                    ForEach(dnsServers.indices, id: \.self) { index in
                        DNSInfoCard(
                            title: "DNS服务器 \(index + 1)",
                            value: dnsServers[index],
                            color: [Color.blue, Color.green, Color.purple, Color.orange][index % 4]
                        )
                    }
                }
            }
            .padding()
            .onAppear {
                fetchDNSProcess()
            }
        })
        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .removeBar()
    }
}

// DNS信息卡片组件
struct DNSInfoCard: View {
    let title: String
    let value: String
    let color: Color
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            // 图标
            Image(systemName: "server.rack")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(color)
                )
                .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 3)
            
            VStack(alignment: .leading, spacing: 4) {
                // 标题
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // 值
                Text(value)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // 复制按钮
            Button(action: {
                #if os(iOS)
                UIPasteboard.general.string = value
                #else
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(value, forType: .string)
                #endif
                ToastManager.shared.show(message: "已复制到剪贴板", type: .success)
            }) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    DNSPage()
}
