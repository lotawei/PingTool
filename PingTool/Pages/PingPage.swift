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
    
    /// 添加初始信息
    func addInitialInfo(address: String, ipAddress: String?) {
        let initialInfo = "PING \(address) (\(ipAddress ?? "Unknown IP")): 56 data bytes"
        addLine(initialInfo)
    }
    /// ping的一次结果
    func addStatistics(result: PingResult, address: String) {
        addLine("--- \(address) ping statistics ---")
        addLine("\(result.packetsTransmitted) packets transmitted, \(result.packetsReceived) packets received, \(String(format: "%.1f", result.packetLoss ?? 0 * 100))% packet loss")
        if let roundtrip = result.roundtrip {
            addLine("average roundtrip time: \(String(format: "%.3f", roundtrip.average * 1000)) ms")
        }
    }
    
}

struct PingPage: View{
    
    @ObservedObject var pingData = PingData()
    @State var pingResult: PingResponseData? = nil
    @State var inputAddress: String = "www.baidu.com"
    @State var tool: PINGManagerTool =  PINGManagerTool()
    @State private var isPinging = false
    
    var body: some View {
        ItemCardContainer(content: {
            VStack {
                ItemTextField(
                    text: $inputAddress,
                    placeholder: "请输入域名",
                    icon: "scribble",
                    isSecure: false
                )
                
                CommandlineTextView(data: pingData.commandlineData)
                    .frame(maxHeight: .infinity)
                Button {
                    isPinging.toggle()
                    if isPinging {
                        pingData.clearText()
                        pingData.addLine("\n")
                        addInitialPingInfo {
                            tool.pingAddress(address: inputAddress, callbackHandler: callbackhandler,finished: finishedResult)
                        }
                        
                    } else {
                        tool.stopPing()
                    }
                } label: {
                    Text(isPinging ? "Stop..." : "Ping")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }.removeBar()
        })
    }
    
    // 定义 callbackHandler
    var callbackhandler: ObserverPing {
        return { responseData in
            DispatchQueue.main.async {
                self.pingResult = responseData
                pingData.commandlineData.append(responseData.format()) // 直接修改 @Published 变量
            }
        }
    }
    var  finishedResult:FinishedCallback {
        return {
            result in
            DispatchQueue.main.async {
                pingData.addStatistics(result: result, address: inputAddress)
            }
        }
    }
    // 添加初始 PING 信息
    func addInitialPingInfo(synccompletion: @escaping () -> Void) {
        tool.getIPByAddress(address: inputAddress) { ipAddress in
            DispatchQueue.main.async {
                pingData.addInitialInfo(address: inputAddress, ipAddress: ipAddress)
                synccompletion()
            }
        }
    }
}
