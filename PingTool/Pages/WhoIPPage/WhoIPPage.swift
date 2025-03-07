import SwiftUI
import MapKit

struct WhoIPPage: View {
    @StateObject private var viewModel = WhoIPViewModel()
    
    var body: some View {
        ItemCardContainer {
            ScrollView {
                refreshButton
                
                if let errorMessage = viewModel.errorMessage {
                    ErrorView(message: errorMessage, retryAction: viewModel.fetchIPInfo)
                } else {
                    LazyVStack(spacing: 20) {
                        ipAddressSection
                        locationSection
                        ispSection
                        mapSection
                        timezoneSection
                    }
                }
            }
        }
        .removeBar()
        .onAppear {
            viewModel.fetchIPInfo()
        }
    }
    
    // 拆分子视图
    private var refreshButton: some View {
        Button(action: viewModel.fetchIPInfo) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                .animation(
                    viewModel.isLoading ?
                        Animation.linear(duration: 1).repeatForever(autoreverses: false) :
                        .default,
                    value: viewModel.isLoading
                )
        }
    }
    
    private var ipAddressSection: some View {
        IPAddressCard(locaip: viewModel.ipInfo.localip, pubip: viewModel.ipInfo.pubip)
    }
    
    private var locationSection: some View {
        LocationCard(
            country: viewModel.ipInfo.country,
            region: viewModel.ipInfo.region,
            city: viewModel.ipInfo.city
        )
    }
    
    private var ispSection: some View {
        InfoCard(
            title: "网络服务商",
            icon: "network",
            content: viewModel.ipInfo.isp
        )
    }
    
    private var mapSection: some View {
        MapCard(region: $viewModel.region)
    }
    
    private var timezoneSection: some View {
        InfoCard(
            title: "时区",
            icon: "clock",
            content: viewModel.ipInfo.timezone
        )
    }
}

// 错误视图
struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: retryAction) {
                Text("重试")
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}







// 地图卡片组件
struct MapCard: View {
    @Binding var region: MKCoordinateRegion
    
    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 15) {
                CardHeader(title: "位置", icon: "map")
                
                Map(coordinateRegion: $region)
                    .frame(height: 300)
                    .cornerRadius(8)
            }
        }
    }
}
// IP地址卡片组件
struct IPAddressCard: View {
    let locaip: String
    let pubip: String
    @State private var isHovered = false
    
    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 15) {
                CardHeader(title: "IP 地址", icon: "network.badge.shield.half.filled")
                
                VStack(alignment: .leading, spacing: 16) {
                    IPRow(title: "本地 IP", value: locaip, icon: "house.circle.fill")
                    Divider()
                        .background(LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                    IPRow(title: "公网 IP", value: pubip, icon: "globe.americas.fill")
                }
                .padding(.vertical, 8)
            }
        }
        .animation(.spring(), value: isHovered)
    }
}

// 地理位置卡片组件
struct LocationCard: View {
    let country: String
    let region: String
    let city: String
    
    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 15) {
                CardHeader(title: "地理位置", icon: "mappin.and.ellipse")
                
                HStack(spacing: 12) {
                    LocationItem(title: "国家", value: country, icon: "flag.circle.fill")
                    LocationItem(title: "地区", value: region, icon: "building.columns.circle.fill")
                    LocationItem(title: "城市", value: city, icon: "building.2.crop.circle.fill")
                }
                .padding(.vertical, 8)
            }
        }
    }
}

// 通用信息卡片组件
struct InfoCard: View {
    let title: String
    let icon: String
    let content: String
    
    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 15) {
                CardHeader(title: title, icon: icon)
                Text(content)
                    .font(.system(.body, design: .rounded))
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.05))
                    )
            }
        }
    }
}


// 卡片头部组件
struct CardHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.blue)
            }
            
            Text(title)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.semibold)
            
            Spacer()
            
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 4 + CGFloat(i), height: 4 + CGFloat(i))
            }
        }
    }
}

// IP行组件
struct IPRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue.opacity(0.7))
            
            Text(title)
                .foregroundColor(.secondary)
                .font(.system(.subheadline, design: .rounded))
            
            Spacer()
            
            Text(value)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
        }
    }
}

// 位置信息项组件
struct LocationItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(.blue)
            }
            
            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.05))
        )
    }
}
