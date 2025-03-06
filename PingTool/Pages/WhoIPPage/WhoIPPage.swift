import SwiftUI
import MapKit

struct WhoIPPage: View {
    @StateObject private var viewModel = WhoIPViewModel()
    var body: some View {
        ItemCardContainer {
            ScrollView {
                Button(action: viewModel.fetchIPInfo) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                        .animation(viewModel.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isLoading)
                }
                VStack(spacing: 20) {
                   if let errorMessage = viewModel.errorMessage {
                        ErrorView(message: errorMessage, retryAction: {
                            viewModel.fetchIPInfo()
                        })
                    } else {
                        // IP 地址卡片
                        IPAddressCard(locaip: viewModel.ipInfo.localip, pubip: viewModel.ipInfo.pubip)
                        
                        // 地理位置卡片
                        LocationCard(country: viewModel.ipInfo.country,
                                   region: viewModel.ipInfo.region,
                                   city: viewModel.ipInfo.city)
                        
                        // ISP 卡片
                        InfoCard(title: "网络服务商",
                                icon: "network",
                                content: viewModel.ipInfo.isp)
                        
                        // 地图卡片
                        MapCard(region: $viewModel.region)
                        
                        // 时区卡片
                        InfoCard(title: "时区",
                                icon: "clock",
                                content: viewModel.ipInfo.timezone)
                    }
                }
            }

        }
        .removeBar()
        .onAppear {
            viewModel.fetchIPInfo()
        }
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



// ... existing code ...

// IP地址卡片组件
struct IPAddressCard: View {
    let locaip: String
    let pubip: String
    
    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 15) {
                CardHeader(title: "IP 地址", icon: "network")
                
                VStack(alignment: .leading, spacing: 12) {
                    IPRow(title: "Local Ip", value: locaip)
                    Divider()
                    IPRow(title: "Public Ip", value: pubip)
                }
            }
        }
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
                CardHeader(title: "地理位置", icon: "mappin.circle")
                
                HStack(spacing: 20) {
                    LocationItem(title: "国家", value: country)
                    LocationItem(title: "地区", value: region)
                    LocationItem(title: "城市", value: city)
                }
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
            }
        }
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
                    .frame(height: 200)
                    .cornerRadius(8)
            }
        }
    }
}

// 通用卡片容器
struct CardContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// 卡片头部组件
struct CardHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(title)
                .font(.headline)
            Spacer()
        }
    }
}

// IP行组件
struct IPRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primary)
        }
    }
}

// 位置信息项组件
struct LocationItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// ... existing code ...
