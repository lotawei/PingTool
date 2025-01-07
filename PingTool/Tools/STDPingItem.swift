//
//  STDPingItem.swift
//  PingTool
//
//  Created by work on 2025/1/2.
//

import Foundation
import CoreGraphics

enum STDPingStatus: Int {
    case didStart
    case didFailToSendPacket
    case didReceivePacket
    case didReceiveUnexpectedPacket
    case didTimeout
    case error
    case finished
}

class STDPingItem: NSObject {
    // Target original address
    var originalAddress: String?
    
    // Target IP address (32-bit IP)
    var IPAddress: String?
    
    // Data length
    var dateBytesLength: Int = 0
    
    // Response time in milliseconds
    var timeMilliseconds: Double = 0.0
    
    // TTL (Time to Live) request lifecycle, routing hops
    var timeToLive: Int = 0
    
    // Routing hops
    var tracertCount: Int = 0
    
    // ICMP sequence
    var ICMPSequence: Int = 0
    
    // Ping status
    var status: STDPingStatus = .didStart
    
    // Static method to calculate statistics from an array of ping items
    static func statistics(withPingItems pingItems: [STDPingItem]) -> String {
        // Implement statistics calculation logic here
        guard let address = pingItems.first?.originalAddress else {
              return ""
          }
          
          var receivedCount = 0
          var allCount = 0
          
          pingItems.forEach { obj in
              if obj.status != .finished && obj.status != .error {
                  allCount += 1
                  if obj.status == .didReceivePacket {
                      receivedCount += 1
                  }
              }
          }
          var description = "--- \(address) ping statistics ---\n"
          let lossPercent = CGFloat(allCount - receivedCount) / max(1.0, CGFloat(allCount)) * 100
          description += String(format: "%ld packets transmitted, %ld packets received, %.1f%% packet loss\n", allCount, receivedCount, lossPercent)
          
          return description.replacingOccurrences(of: ".0%", with: "%")
    }
    override var description: String {
        switch status {
        case .didStart:
            return String(format: "PING %@ (%@): %ld data bytes", originalAddress ?? "", IPAddress ?? "", dateBytesLength)
        case .didReceivePacket:
            return String(format: "%ld bytes from %@: icmp_seq=%ld ttl=%ld time=%.3f ms", dateBytesLength, IPAddress ?? "", ICMPSequence, timeToLive, timeMilliseconds)
        case .didTimeout:
            return String(format: "Request timeout for icmp_seq %ld, ttl = %ld", ICMPSequence, timeToLive)
        case .didFailToSendPacket:
            return String(format: "Fail to send packet to %@: icmp_seq=%ld", IPAddress ?? "", ICMPSequence)
        case .didReceiveUnexpectedPacket:
            return String(format: "Receive unexpected packet from %@: icmp_seq=%ld", IPAddress ?? "", ICMPSequence)
        case .error:
            return String(format: "Cannot ping to %@", originalAddress ?? "")
        default:
            break
        }
        return super.description
    }
}

class STDPingServices {
    // Timeout in milliseconds (default 500ms)
    var timeoutMilliseconds: Double = 500.0
    
    // Maximum ping times
    var maximumPingTimes: Int = 0

    
    
    // private propertities
    private var hasStarted: Bool = false
    private var isTimeout: Bool = false
    private var repingTimes: Int = 0
    private var sequenceNumber: Int = 0
    private var pingItems: [STDPingItem] = []
    private var address: String?
    private var simplePing: STSimplePing?
    private var callbackHandler: ((STDPingItem, [STDPingItem]) -> Void)?
    // Start pinging the address with a callback handler
    class func startPingAddress(_ address: String, callbackHandler: @escaping (STDPingItem, [STDPingItem]) -> Void) -> STDPingServices {
        let service = STDPingServices(address: address)
        service.callbackHandler = callbackHandler
        service.startping()
        // Implement the pinging logic here and call the callback handler
        return service
    }
    
    // Cancel the pinging process
    func cancel() {
        // 取消之前安排的超时处理方法
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(timeoutActionFired), object: nil)
        // 停止 Ping 操作
        simplePing?.stop()
        
        // 创建并添加一个 finished 状态的 Ping 项
        let pingItem = STDPingItem()
        pingItem.status = .finished
        pingItems.append(pingItem)
        // 调用回调函数
        callbackHandler?(pingItem, pingItems)
    }
    func startping(){
        self.repingTimes = 0;
        hasStarted = false;
        pingItems.removeAll()
        self.simplePing?.start()
    }
    init(address: String) {
        self.timeoutMilliseconds = 500
        self.maximumPingTimes = 100
        self.address = address
        self.simplePing = STSimplePing(hostName: address)
        self.simplePing?.addressStyle = .any
        self.simplePing?.delegate = self
        self.pingItems = [STDPingItem]()
    }
    @objc func reling(){
        self.simplePing?.stop()
        self.simplePing?.start()
    }
    @objc func timeoutActionFired(){
       let  pingitem =  STDPingItem();
        pingitem.ICMPSequence = self.sequenceNumber
        pingitem.originalAddress = self.address
        pingitem.status = STDPingStatus.didTimeout
        self.simplePing?.stop()
        self.handlePingItem(pingitem)
        
    }
    private func handlePingItem(_ pingItem: STDPingItem) {
        if pingItem.status == .didReceivePacket || pingItem.status == .didTimeout {
            pingItems.append(pingItem)
        }
        if repingTimes < self.maximumPingTimes - 1 {
            callbackHandler?(pingItem, pingItems)
            repingTimes += 1
            let timer = Timer(timeInterval: timeoutMilliseconds, target: self, selector: #selector(self.reling), userInfo: nil, repeats: false)
            RunLoop.current.add(timer, forMode: .common)
        } else {
            callbackHandler?(pingItem,pingItems)
            cancel()
        }
    }
    
}

extension STDPingServices:STSimplePingDelegate {
    
    func simplePing(_ pinger: STSimplePing, didStartWithAddress address: Data) {
        let packet = pinger.packetWithPingData(address) ?? Data()
        if !self.hasStarted {
            let pingItem = STDPingItem()
            pingItem.IPAddress = pinger.ipAddress
            pingItem.originalAddress = self.address
            pingItem.dateBytesLength = packet.count - MemoryLayout<STICMPHeader>.size
            pingItem.status = .didStart
            callbackHandler?(pingItem, [])
            hasStarted = true
        }

        pinger.sendPacket(packet)
        //待优化 后续 放在子线程去操作
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutMilliseconds / 1000.0) {
            self.timeoutActionFired()
        }
    }
    
    func simplePing(_ pinger: STSimplePing, didFailWithError error: Error) {
        Logger.debug("----- didFailWithError")
        // 取消之前安排的超时处理方法
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(timeoutActionFired), object: nil)
        self.simplePing?.stop()
        self.sequenceNumber = Int(sequenceNumber);
        // 创建并添加一个 finished 状态的 Ping 项
        let errorItem = STDPingItem()
        errorItem.ICMPSequence = self.sequenceNumber
        errorItem.originalAddress = self.address
        errorItem.status = STDPingStatus.error
        self.callbackHandler?(errorItem,self.pingItems)
        
        let pingItem = STDPingItem()
        pingItem.ICMPSequence = self.sequenceNumber
        pingItem.originalAddress = self.address
        pingItem.IPAddress = pinger.ipAddress ?? pinger.hostName
        pingItem.status = STDPingStatus.finished
        self.pingItems.append(pingItem)
        self.callbackHandler?(errorItem,self.pingItems)
    }
    
    func simplePing(_ pinger: STSimplePing, didSendPacket packet: Data, sequenceNumber: UInt16) {
        Logger.debug("----- didSendPacket")
        self.sequenceNumber = Int(sequenceNumber)
    }
    
    func simplePing(_ pinger: STSimplePing, didFailToSendPacket packet: Data, sequenceNumber: UInt16, error: Error) {
        Logger.debug("----- didFailToSendPacket")
        // 取消之前安排的超时处理方法
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(timeoutActionFired), object: nil)
        self.sequenceNumber = Int(sequenceNumber);
        // 创建并添加一个 finished 状态的 Ping 项
        let pingItem = STDPingItem()
        pingItem.ICMPSequence = self.sequenceNumber
        pingItem.originalAddress = self.address
        pingItem.status = STDPingStatus.didFailToSendPacket
        // 调用回调函数
        handlePingItem(pingItem)
    }
    
    func simplePing(_ pinger: STSimplePing, didReceivePingResponsePacket packet: Data, timeToLive: Int, sequenceNumber: UInt16, timeElapsed: TimeInterval) {
        Logger.debug("----- didReceivePingResponsePacket")
        // 取消之前安排的超时处理方法
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(timeoutActionFired), object: nil)
        // 创建并添加一个 finished 状态的 Ping 项
        let pingItem = STDPingItem()
        pingItem.IPAddress = pinger.ipAddress
        pingItem.dateBytesLength = packet.count
        pingItem.timeToLive = timeToLive
        pingItem.timeMilliseconds = timeElapsed * 1000;
        pingItem.ICMPSequence = self.sequenceNumber;
        pingItem.originalAddress = self.address
        pingItem.status = STDPingStatus.didReceivePacket
        // 调用回调函数
        handlePingItem(pingItem)
    }
    
    func simplePing(_ pinger: STSimplePing, didReceiveUnexpectedPacket packet: Data) {
        Logger.debug("----- didReceiveUnexpectedPacket")
        // 取消之前安排的超时处理方法
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(timeoutActionFired), object: nil)
        // 创建并添加一个 finished 状态的 Ping 项
        let pingItem = STDPingItem()
        pingItem.ICMPSequence = self.sequenceNumber
        pingItem.originalAddress = self.address
        pingItem.status = STDPingStatus.didReceiveUnexpectedPacket
        // 调用回调函数
        handlePingItem(pingItem)
    }
    
    
    
}
