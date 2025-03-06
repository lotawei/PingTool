import SwiftUI
import Combine

class PingData: ObservableObject {
    @Published var commandlineData: [String] = []
    func addLine(_ line: String) {
        commandlineData.append(line)
    }
    func clearText() {
        objectWillChange.send()
        commandlineData.removeAll()
    }
    
    func addInitialInfo(address: String, ipAddress: String?) {
        let initialInfo = "PING \(address) (\(ipAddress ?? "Unknown IP")): 56 data bytes"
        addLine(initialInfo)
    }
    
    func addStatistics(result: PingResult, address: String) {
        addLine("--- \(address) ping statistics ---")
        addLine("\(result.packetsTransmitted) packets transmitted, \(result.packetsReceived) packets received, \(String(format: "%.1f", result.packetLoss ?? 0 * 100))% packet loss")
        if let roundtrip = result.roundtrip {
            addLine("average roundtrip time: \(String(format: "%.3f", roundtrip.average * 1000)) ms")
        }
    }
}

struct PingPage: View {
    @ObservedObject var pingData = PingData()
    @State var pingResult: PingResponseData? = nil
    @State var inputAddress: String = "www.baidu.com"
    @State var tool: PINGManagerTool = PINGManagerTool()
    @State private var isPinging = false
    
    var body: some View {
        ItemCardContainer(content: {
            VStack {
                // 顶部输入区域
                VStack(alignment: .leading, spacing: 12) {
                    
                    Text("Ping测试")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                    
                    ItemTextField(
                        text: $inputAddress,
                        placeholder: "请输入域名或IP地址",
                        icon: "network",
                        isSecure: false
                    )
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // 命令行输出区域
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("测试结果")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        // 状态指示器
                        if isPinging {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("测试中...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    CommandlineTextView(data: pingData.commandlineData)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                .padding(.horizontal)
                
                // 底部按钮
                Button(action: {
                    isPinging.toggle()
                    if isPinging {
                        pingData.clearText()
                        pingData.addLine("\n")
                        addInitialPingInfo {
                            tool.pingAddress(address: inputAddress, callbackHandler: callbackhandler, finished: finishedResult)
                        }
                    } else {
                        tool.stopPing()
                    }
                })
                {
                    HStack {
                        Image(systemName: isPinging ? "stop.circle.fill" : "play.circle.fill")
                            .font(.title2)
                        Text(isPinging ? "停止测试" : "开始测试")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isPinging ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            .padding(.vertical)
            .removeBar()
        })
        .onDisappear{
            tool.stopPing()
            pingData.clearText()
            
        }
    }
    
    var callbackhandler: ObserverPing {
        return { responseData in
            DispatchQueue.main.async {
                self.pingResult = responseData
                pingData.commandlineData.append(responseData.format())
            }
        }
    }
    
    var finishedResult: FinishedCallback {
        return { result in
            DispatchQueue.main.async {
                pingData.addStatistics(result: result, address: inputAddress)
            }
        }
    }
    
    func addInitialPingInfo(synccompletion: @escaping () -> Void) {
        tool.getIPByAddress(address: inputAddress) { ipAddress in
            DispatchQueue.main.async {
                pingData.addInitialInfo(address: inputAddress, ipAddress: ipAddress)
                synccompletion()
            }
        }
    }
}
