//
//  PINGManagerTool.swift
//  PingTool
//
//  Created by work on 2025/1/3.
//

import Foundation
import Network
import SystemConfiguration
protocol NetSpeedResultHandler{
    func  speedNet(speed:Double)
    func  avgSpeed(avgspeed:Double)
}

class PINGManagerTool:NSObject {
    var  updateSpeedHandler:NetSpeedResultHandler? = nil
    private var session: URLSession!
    private var downloadTask: URLSessionDownloadTask?
    private var totalBytesReceived: Int64 = 0
    private var lastBytesReceived: Int64 = 0
    private var startTime: CFAbsoluteTime = 0
    private var lastUpdateTime: CFAbsoluteTime = 0
    
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
    // 删除下载的文件（如果需要）
    func cleanUpDownloadedFile(at url: URL) {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: url)
            print("Downloaded file deleted.")
        } catch {
            print("Failed to delete downloaded file: \(error.localizedDescription)")
        }
    }
    // 设置实时网速更新
    func startSpeedTest(from url: URL, duration: TimeInterval, updateSpeedHandler:NetSpeedResultHandler) {
        self.updateSpeedHandler = updateSpeedHandler
        // 配置 URLSession
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = duration + 5 // 增加超时时间
        configuration.timeoutIntervalForResource = duration + 5
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue())
        
        // 初始化统计参数
        totalBytesReceived = 0
        startTime = CFAbsoluteTimeGetCurrent()
        lastUpdateTime = startTime // 确保 lastUpdateTime 被初始化为 startTime
        lastBytesReceived = 0
        
        // 创建下载任务
        downloadTask = session.downloadTask(with: url)
        downloadTask?.resume()
    }
    
    // 计算下载速度（Mbps）
    // 计算速度
    func calculateSpeed(bytesReceived: Int64, elapsedTime: CFAbsoluteTime) -> Double {
           let bytesPerSecond = Double(bytesReceived) / elapsedTime
        return String.formatMBPerSecond(speed: bytesPerSecond)
    }
    // 取消下载任务
    func cancelDownloadTask() {
        downloadTask?.cancel()
        self.downloadTask = nil
    }
    
}



extension  PINGManagerTool:URLSessionDownloadDelegate,URLSessionDelegate{
    
    // 下载完成，文件保存位置 (URLSessionDownloadDelegate)
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("Download finished to: \(location.path)")
        // 在这里你可以将文件从临时位置移动到永久位置，并进行其他处理
        DispatchQueue.main.async {
            self.cleanUpDownloadedFile(at: location)
        }
    }
    // 下载进度更新 (URLSessionDownloadDelegate)
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print("didWriteData called: bytesWritten = \(bytesWritten), totalBytesWritten = \(totalBytesWritten), totalBytesExpectedToWrite = \(totalBytesExpectedToWrite)")
        totalBytesReceived += bytesWritten
        // 计算时间差
        let currentTime = CFAbsoluteTimeGetCurrent()
        let elapsedTime = currentTime - lastUpdateTime
        
        // 满足0.3秒间隔时更新
        if elapsedTime >= 0.3 {
            let speed = calculateSpeed(
                bytesReceived: totalBytesReceived - lastBytesReceived,
                elapsedTime: elapsedTime
            )
            
            // 主线程更新UI（关键点：确保UI操作在主线程）
            DispatchQueue.main.async { [weak self] in
                self?.updateSpeedHandler?.speedNet(speed: speed)
            }
            
            // 更新记录值
            lastUpdateTime = currentTime
            lastBytesReceived = totalBytesReceived
        }
    }
    
    // 下载完成处理
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error as NSError?, error.code == NSURLErrorCancelled {
            print("Download task canceled.")
        } else if let error = error {
            print("Download failed: \(error.localizedDescription)")
        } else {
            print("Download completed successfully.")
            let totalElapsedTime = CFAbsoluteTimeGetCurrent() - startTime
            let averageSpeedValue = calculateSpeed(bytesReceived: totalBytesReceived, elapsedTime: totalElapsedTime)
            DispatchQueue.main.async {
                self.updateSpeedHandler?.avgSpeed(avgspeed: averageSpeedValue)
            }
            if  let  downloadTask = task as? URLSessionDownloadTask {
                if let url = downloadTask.originalRequest?.url {
                    print("Original URL: \(url.absoluteString)")
                }
                // 获取临时文件路径，并在完成时处理它
                if let tempFileURL = downloadTask.response as? HTTPURLResponse {
                    print("MIMEType: \(tempFileURL.mimeType ?? "noMimeType")")
                    print("FileSize: \(tempFileURL.expectedContentLength)")
                }
               
            }
            
        }
        session.finishTasksAndInvalidate()
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                      completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
          if let serverTrust = challenge.protectionSpace.serverTrust {
              let credential = URLCredential(trust: serverTrust)
              completionHandler(.useCredential, credential)
          } else {
              completionHandler(.cancelAuthenticationChallenge, nil)
          }
      }
}
