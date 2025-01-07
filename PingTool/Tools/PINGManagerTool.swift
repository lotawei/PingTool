//
//  PINGManagerTool.swift
//  PingTool
//
//  Created by work on 2025/1/3.
//

import Foundation
import Network
import SystemConfiguration
struct PINGManagerTool {
    static func getLocalAddressIp() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        
        // 获取网络接口列表
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return nil
        }
        
        // 遍历网络接口列表
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            
            // 获取地址族
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                // 获取接口名称
                let name = String(cString: interface.ifa_name)
                // 过滤非 Wi-Fi 或蜂窝数据的地址
                if name == "en0" { // "en0" 表示 Wi-Fi
                    var addr = interface.ifa_addr.pointee
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(
                        &addr,
                        socklen_t(interface.ifa_addr.pointee.sa_len),
                        &hostname,
                        socklen_t(hostname.count),
                        nil,
                        0,
                        NI_NUMERICHOST
                    ) == 0 {
                        address = String(cString: hostname)
                    }
                }
            }
        }
        
        freeifaddrs(ifaddr) // 释放资源
        return address
    }
    //获取公网IP
    static func getPublicIPAddress(completion: @escaping (String?) -> Void) {
        // 使用公网服务获取外网 IP 地址
        guard let url = URL(string: "https://ifconfig.me/ip") else {
            completion(nil)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10.0 // 设置超时时间
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                Logger.debug("获取公网 IP 失败: \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let data = data, let ipAddress = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                completion(nil)
                return
            }
            completion(ipAddress)
        }
        
        task.resume()
    }
    
    /// fetch dns
    /// - Parameter completion:
    static func fetchDNSServers(completion: @escaping ([String]) -> Void)  {
        guard let fileContent = try? String(contentsOfFile: "/etc/resolv.conf") else {
            Logger.debug("Failed to read resolv.conf")
            completion([])
            return
        }
        
        let dnsServers = fileContent
            .components(separatedBy: "\n")
            .filter { $0.hasPrefix("nameserver") }
            .compactMap { line -> String? in
                let components = line.split(separator: " ")
                return components.count > 1 ? String(components[1]) : nil
            }
        
        completion(dnsServers)
    }
    
    static func getSubnetMask(completion: @escaping (String?) -> Void) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        
        // 获取网络接口列表
        guard getifaddrs(&ifaddr) == 0 else {
            Logger.debug("Error: Unable to get network interfaces")
            return
        }
        
        var pointer = ifaddr
        while pointer != nil {
            if let interface = pointer?.pointee {
                // 检查是否为 IPv4 地址
                if interface.ifa_addr.pointee.sa_family == UInt8(AF_INET) {
                    let name = String(cString: interface.ifa_name) // 网络接口名称
                    if name == "en0" { // 通常 "en0" 是 Wi-Fi 接口，可以根据需要更改
                        // 获取子网掩码
                        var netmask = sockaddr_in()
                        memcpy(&netmask, interface.ifa_netmask, MemoryLayout<sockaddr_in>.size)
                        let netmaskString = String(cString: inet_ntoa(netmask.sin_addr), encoding: .ascii) ?? "Unknown"
                        Logger.debug("Interface: \(name)")
                        Logger.debug("Subnet Mask: \(netmaskString)")
                        completion(netmaskString)
                        return
                    }
                }
                
            }
            pointer = pointer?.pointee.ifa_next
            
        }
        completion(nil)
        freeifaddrs(ifaddr) // 释放资源
    }
    
    /// 获取默认网关 IP 地址
        /// - Returns: 默认网关 IP 地址
        static func getDefaultGateway() -> String? {
            #if os(macOS)
            return getDefaultGatewayMacOS()
            #elseif os(iOS)
            return getDefaultGatewayiOS()
            #else
            return nil
            #endif
        }
        #if os(macOS)
        /// macOS: 使用 netstat 命令获取默认网关
        private static func getDefaultGatewayMacOS() -> String? {
            let command = "netstat -rn"
            let pipe = Pipe()
            let process = Process()
            process.standardOutput = pipe
            process.standardError = pipe
            process.launchPath = "/bin/bash"
            process.arguments = ["-c", command]
            process.launch()
            
            // 读取输出结果
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            
            if let output = String(data: data, encoding: .utf8) {
                // 解析网关地址
                let lines = output.split(separator: "\n")
                for line in lines {
                    let components = line.split(separator: " ", omittingEmptySubsequences: true)
                    if components.count >= 2 && components[0] == "default" {
                        return String(components[1]) // 默认网关 IP
                    }
                }
            }
            return nil
        }
        #endif
        #if os(iOS)
        
        /// iOS: 使用 SystemConfiguration 获取网络信息
        private static func getDefaultGatewayiOS() -> String? {
            var zeroAddress = sockaddr_in()
            zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
            zeroAddress.sin_family = sa_family_t(AF_INET)
            
            guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
                    SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
                }
            }) else {
                return nil
            }
            
            var flags: SCNetworkReachabilityFlags = []
            if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
                return nil
            }
            
            if flags.contains(.reachable) && !flags.contains(.connectionRequired) {
                return getWiFiGatewayIP()
            }
            
            return nil
        }
        #endif
        
        /// iOS: 获取 Wi-Fi 网关 IP 地址
        private static func getWiFiGatewayIP() -> String? {
            var ifaddr: UnsafeMutablePointer<ifaddrs>?
            guard getifaddrs(&ifaddr) == 0 else { return nil }
            var pointer = ifaddr
            defer { freeifaddrs(ifaddr) }
            
            while pointer != nil {
                let interface = pointer!.pointee
                let name = String(cString: interface.ifa_name)
                
                if name == "en0", interface.ifa_addr.pointee.sa_family == UInt8(AF_INET) {
                    var address = sockaddr_in()
                    memcpy(&address, interface.ifa_addr, MemoryLayout<sockaddr_in>.size)
                    let ipString = String(cString: inet_ntoa(address.sin_addr), encoding: .ascii)
                    return ipString
                }
                pointer = interface.ifa_next
            }
            return nil
        }
    
        //https://nbg1-speed.hetzner.com/100MB.bin
    // 实时下载速度测试
   static func testDownloadSpeedWithLiveUpdate(from url: URL, duration: TimeInterval = 5, completion: @escaping (Double) -> Void) {
        
        // 计算下载速度（Mbps）
      func calculateSpeed(bytesDownloaded: Int, elapsedTime: TimeInterval) -> Double {
            return (Double(bytesDownloaded) * 8) / (elapsedTime * 1_000_000) // 转换为Mbps
      }
        // 创建子线程进行测试
        DispatchQueue.global(qos: .background).async {
            let startTime = CFAbsoluteTimeGetCurrent()
            var totalBytesDownloaded: Int = 0
            var lastUpdateTime = startTime
            var lastBytesDownloaded = 0
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    completion(0)
                    return
                }

                if let data = data {
                    totalBytesDownloaded += data.count
                }

                // 每隔一段时间更新一次速度
                if elapsedTime - lastUpdateTime >= 1.0 {  // 每秒更新一次
                    let currentSpeedInMbps = calculateSpeed(bytesDownloaded: totalBytesDownloaded - lastBytesDownloaded, elapsedTime: elapsedTime - lastUpdateTime)
                    DispatchQueue.main.async {
                        completion(currentSpeedInMbps)
                    }
                    lastUpdateTime = elapsedTime
                    lastBytesDownloaded = totalBytesDownloaded
                }

                if elapsedTime >= duration {
                    // 计算最终下载速度
                    let speedInMbps = calculateSpeed(bytesDownloaded: totalBytesDownloaded, elapsedTime: elapsedTime)
                    DispatchQueue.main.async {
                        completion(speedInMbps)
                    }

                    // 清理文件
                    cleanUpDownloadedFile(at: url)
                } else {
                    // 继续下载数据直到达到指定时间
                    testDownloadSpeedWithLiveUpdate(from: url, duration: duration, completion: completion)
                }
            }

            task.resume()

            // 保持程序运行，等待下载完成
            RunLoop.main.run()
        }
    }

    // 删除下载的文件（如果需要）
   static func cleanUpDownloadedFile(at url: URL) {
        // 假设你下载的文件是存储在本地的临时文件，可以根据情况调整路径
        let fileManager = FileManager.default
        let tempFilePath = "/path/to/temp/file"  // 临时文件路径

        do {
            if fileManager.fileExists(atPath: tempFilePath) {
                try fileManager.removeItem(atPath: tempFilePath)
                print("Temporary file deleted.")
            }
        } catch {
            print("Failed to delete temporary file: \(error.localizedDescription)")
        }
    }

    
}
