import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct IpPage: View {
    @State private var localip: String = "0.0.0.0"
    @State private var outsideip: String = "0.0.0.0"
    @State private var outmaskip: String = "0.0.0.0"
    @State private var routerip: String = "0.0.0.0"
    @State private var isRefreshing = false
    
    private let gradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "4158D0").opacity(0.8),
            Color(hex: "C850C0").opacity(0.8),
            Color(hex: "FFCC70").opacity(0.8)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    fileprivate func fetchIpProcess() {
        withAnimation {
            isRefreshing = true
        }
        
        localip = PINGManagerTool.getLocalAddressIp() ?? "未获取到"
        
        PINGManagerTool.getPublicIPAddress { value in
            guard let aip = value else {
                DispatchQueue.main.async {
                    ToastManager.shared.show(message: "IP获取失败", type: .error)
                    withAnimation {
                        isRefreshing = false
                    }
                }
                return
            }
            DispatchQueue.main.async {
                outsideip = aip
            }
        }
        
        PINGManagerTool.getSubnetMask { value in
            guard let submask = value else {
                DispatchQueue.main.async {
                    ToastManager.shared.show(message: "子网掩码获取失败", type: .error)
                }
                return
            }
            DispatchQueue.main.async {
                outmaskip = submask
            }
        }
        
        routerip = PINGManagerTool.getDefaultGateway() ?? "empty"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation {
                isRefreshing = false
            }
        }
    }
    
    var body: some View {
        ItemCardContainer(content: {
            VStack(spacing: 20) {
                // 刷新按钮
                Button(action: fetchIpProcess) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(isRefreshing ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                }
                
                // IP信息卡片
                LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                    IPInfoCard(title: "本地IP地址", value: localip, icon: "network", color: .blue)
                    IPInfoCard(title: "外网IP地址", value: outsideip, icon: "globe", color: .green)
                    IPInfoCard(title: "子网掩码", value: outmaskip, icon: "shield.lefthalf.filled", color: .purple)
                    IPInfoCard(title: "路由器地址", value: routerip, icon: "router", color: .orange)
                }
            }
            .padding()
            .onAppear {
                fetchIpProcess()
            }
        })
        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .removeBar()
    }
}

// IP信息卡片组件
struct IPInfoCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            // 图标
            Image(systemName: icon)
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
    IpPage()
}
