

import CFNetwork
import Foundation
import Darwin
import libkern
enum STSimplePingAddressStyle: Int {
    case any          // Use the first IPv4 or IPv6 address found; the default.
    case icmpv4       // Use the first IPv4 address found.
    case icmpv6       // Use the first IPv6 address found.
}

struct STIPv4Header {
    var versionAndHeaderLength: UInt8          // Version and header length
    var differentiatedServices: UInt8         // Differentiated services
    var totalLength: UInt16                   // Total length
    var identification: UInt16                // Identification
    var flagsAndFragmentOffset: UInt16        // Flags and fragment offset
    var timeToLive: UInt8                     // Time to live (TTL)
    var `protocol`: UInt8                       // Protocol type
    var headerChecksum: UInt16                // Header checksum
    var sourceAddress: (UInt8, UInt8, UInt8, UInt8) // Source address (IPv4: 4 bytes)
    var destinationAddress: (UInt8, UInt8, UInt8, UInt8) // Destination address (IPv4: 4 bytes)
    // Add options and data as needed
}

// 定义 ICMP 头部结构
struct STICMPHeader {
    var type: UInt8            // ICMP 类型
    var code: UInt8            // ICMP 代码
    var checksum: UInt16       // 校验和
    var identifier: UInt16     // 标识符
    var sequenceNumber: UInt16 // 序列号
    // 检查结构大小
    static func validate() {
        assert(MemoryLayout<STICMPHeader>.size == 8, "STICMPHeader size must be 8 bytes")
        assert(MemoryLayout.offset(of: \STICMPHeader.type) == 0, "Offset of type should be 0")
        assert(MemoryLayout.offset(of: \STICMPHeader.code) == 1, "Offset of code should be 1")
        assert(MemoryLayout.offset(of: \STICMPHeader.checksum) == 2, "Offset of checksum should be 2")
        assert(MemoryLayout.offset(of: \STICMPHeader.identifier) == 4, "Offset of identifier should be 4")
        assert(MemoryLayout.offset(of: \STICMPHeader.sequenceNumber) == 6, "Offset of sequenceNumber should be 6")
    }
    
}

// 定义 ICMP 类型（IPv4 和 IPv6）
enum STICMPv4Type: UInt8 {
    case echoRequest = 8  // Ping 请求
    case echoReply = 0    // Ping 响应
}

enum STICMPv6Type: UInt8 {
    case echoRequest = 128 // Ping 请求
    case echoReply = 129   // Ping 响应
}

protocol STSimplePingDelegate {
    
    func simplePing(_ pinger: STSimplePing, didStartWithAddress address: Data)
    func simplePing(_ pinger: STSimplePing, didFailWithError error: Error)
    func simplePing(_ pinger: STSimplePing, didSendPacket packet: Data, sequenceNumber: UInt16)
    func simplePing(_ pinger: STSimplePing, didFailToSendPacket packet: Data, sequenceNumber: UInt16, error: Error)
    func simplePing(_ pinger: STSimplePing, didReceivePingResponsePacket packet: Data, timeToLive: Int, sequenceNumber: UInt16, timeElapsed: TimeInterval)
    func simplePing(_ pinger: STSimplePing, didReceiveUnexpectedPacket packet: Data)
}
func STHostResolveCallback(theHost: CFHost, typeInfo: CFHostInfoType, error: UnsafePointer<CFStreamError>?, info: UnsafeMutableRawPointer?) {
    // This Swift function is called by CFHost when the host resolution is complete.
    // It just redirects the call to the appropriate method of the STSimplePing instance.
    
    guard let info = info else { return }
    
    let obj = Unmanaged<STSimplePing>.fromOpaque(info).takeUnretainedValue()
    assert(theHost == obj.host)
    assert(typeInfo == CFHostInfoType.addresses)
    if let error = error, error.pointee.domain != 0 {
        obj.didFailWithHostStreamError(error.pointee)
    } else {
        obj.hostResolutionDone()
    }
}
@objcMembers class STSimplePing {
    private(set) var hostAddress: Data? //主机地址
    private(set) var ipAddress: String? // ip地址
    private(set) var identifier: UInt16 = UInt16.random(in: 0...UInt16.max)
    private(set) var nextSequenceNumber: UInt16 = 0
    private var nextSequenceNumberHasWrapped: Bool = false
    var host: CFHost? = nil
    private var socket: CFSocket? = nil
    
    func  startWithHostAddress(){
        var  err:Int = 0;
        var  fd = -1;
        assert(self.hostAddress != nil)
        switch Int32(self.hostAddressFamily) {
        case AF_INET:
            fd = Int(Darwin.socket(AF_INET,SOCK_DGRAM,IPPROTO_ICMP))
            if(fd < 0){
                err = Int(errno)
            }
            break;
        case AF_INET6:
            fd = Int(Darwin.socket(AF_INET6, SOCK_DGRAM, IPPROTO_ICMPV6));
            if (fd < 0) {
                err = Int(errno);
            }
            break;
        default:
            err = Int(EPROTONOSUPPORT)
            break
            
        }
        if(err != 0){
            self.didFailWithError(NSError(domain: NSPOSIXErrorDomain, code: err, userInfo: nil))
        }
        
    }
    func didFailWithError(_ error: NSError) {
        stop() // Assuming `stop()` method exists to handle stopping the ping.
        self.delegate?.simplePing(self, didFailWithError: error)
    }
    // MARK: - Properties
    let hostName: String
    var delegate: STSimplePingDelegate?
    var addressStyle: STSimplePingAddressStyle = .any
    var hostAddressFamily: sa_family_t {
        guard let hostAddress = hostAddress, hostAddress.count >= MemoryLayout<sockaddr>.size else {
            return sa_family_t(AF_UNSPEC)
        }
        
        return hostAddress.withUnsafeBytes { bufferPointer in
            let sockaddrPointer = bufferPointer.bindMemory(to: sockaddr.self).baseAddress
            return sockaddrPointer?.pointee.sa_family ?? sa_family_t(AF_UNSPEC)
        }
    }
    
    var pingStartDate: Date = Date()
    func st_in_cksum(buffer: UnsafeRawPointer, bufferLen: Int) -> UInt16 {
        var bytesLeft = bufferLen
        var sum: UInt32 = 0
        var cursor = buffer.bindMemory(to: UInt16.self, capacity: bufferLen / 2)
        
        var last = (us: UInt16(0), uc: (UInt8(0), UInt8(0)))
        
        // 累加 16 位字
        while bytesLeft > 1 {
            sum += UInt32(cursor.pointee)
            cursor = cursor.advanced(by: 1)
            bytesLeft -= 2
        }
        
        // 处理奇数个字节
        if bytesLeft == 1 {
            last.uc.0 = buffer.load(fromByteOffset: bufferLen - 1, as: UInt8.self)
            last.uc.1 = 0
            sum += UInt32(last.us)
        }
        
        // 处理进位
        sum = (sum >> 16) + (sum & 0xffff)
        sum += (sum >> 16)
        
        let answer = UInt16(~sum & 0xffff)
        return answer
    }
    
    // 编译时检查等价的运行时检查
    static func checkMemoryLayout() {
        assert(MemoryLayout<STIPv4Header>.size == 20, "Size of STIPv4Header is not 20 bytes")
        assert(MemoryLayout.offset(of: \STIPv4Header.versionAndHeaderLength) == 0, "Offset of versionAndHeaderLength is incorrect")
        assert(MemoryLayout.offset(of: \STIPv4Header.differentiatedServices) == 1, "Offset of differentiatedServices is incorrect")
        assert(MemoryLayout.offset(of: \STIPv4Header.totalLength) == 2, "Offset of totalLength is incorrect")
        assert(MemoryLayout.offset(of: \STIPv4Header.identification) == 4, "Offset of identification is incorrect")
        assert(MemoryLayout.offset(of: \STIPv4Header.flagsAndFragmentOffset) == 6, "Offset of flagsAndFragmentOffset is incorrect")
        assert(MemoryLayout.offset(of: \STIPv4Header.timeToLive) == 8, "Offset of timeToLive is incorrect")
        assert(MemoryLayout.offset(of: \STIPv4Header.protocol) == 9, "Offset of protocol is incorrect")
        assert(MemoryLayout.offset(of: \STIPv4Header.headerChecksum) == 10, "Offset of headerChecksum is incorrect")
        assert(MemoryLayout.offset(of: \STIPv4Header.sourceAddress) == 12, "Offset of sourceAddress is incorrect")
        assert(MemoryLayout.offset(of: \STIPv4Header.destinationAddress) == 16, "Offset of destinationAddress is incorrect")
    }
    
    
    
    
    // MARK: - Initializer
    
    init(hostName: String) {
        self.hostName = hostName
        self.identifier = UInt16.random(in: 0...UInt16.max)
        
    }
    // MARK: - Methods
    func didFailWithHostStreamError(_ streamError: CFStreamError) {
        var userInfo: [String: Any]?
        var error: NSError
        
        if streamError.domain == kCFStreamErrorDomainNetDB {
            userInfo = [kCFGetAddrInfoFailureKey as String: NSNumber(value: streamError.error)]
        } else {
            userInfo = nil
        }
        
        error = NSError(domain: "kCFErrorDomainCFNetwork", code: 2, userInfo: userInfo)
        
        didFailWithError(error)
    }
    /// Builds a ping packet from the supplied parameters.
    /// - Parameters:
    ///   - type: The packet type, which is different for IPv4 and IPv6.
    ///   - payload: Data to place after the ICMP header.
    ///   - requiresChecksum: Determines whether a checksum is calculated (IPv4) or not (IPv6).
    /// - Returns: A ping packet suitable to be passed to the kernel.
    func pingPacket(type: UInt8, payload: Data, requiresChecksum: Bool) -> Data {
        let packet = Data(count: MemoryLayout<STICMPHeader>.size + payload.count)
        var temporaryPacket = packet
        temporaryPacket.withUnsafeMutableBytes { rawBufferPointer in
            guard let icmpPtr = rawBufferPointer.bindMemory(to: STICMPHeader.self).baseAddress else {
                fatalError("Unable to create ICMP pointer")
            }
            
            // Fill ICMP header
            icmpPtr.pointee.code = type
            icmpPtr.pointee.code = 0
            icmpPtr.pointee.checksum = 0
            icmpPtr.pointee.identifier = identifier.bigEndian
            icmpPtr.pointee.sequenceNumber = nextSequenceNumber.bigEndian
            
            // Copy payload data
            let payloadStart = rawBufferPointer.baseAddress!.advanced(by: MemoryLayout<STICMPHeader>.size)
            payload.copyBytes(to: payloadStart.assumingMemoryBound(to: UInt8.self), count: payload.count)
            
            // Calculate checksum if required
            if requiresChecksum {
                let checksum = st_in_cksum(buffer: icmpPtr,bufferLen: packet.count)
                icmpPtr.pointee.checksum = checksum
            }
        }
        return packet
    }
    
    func start() {
        var success: Bool
        var context = CFHostClientContext(
            version: 0,
            info: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        var streamError = CFStreamError()
        
        assert(host == nil)
        assert(hostAddress == nil)
        
        // Create CFHost with the provided hostName
        host = CFHostCreateWithName(nil, hostName as CFString).takeRetainedValue()
        guard let host = host else{
            return
        }
        
        // Set the client callback for host resolution
        //        CFHostSetClient(host, STSimplePing., &context)
        CFHostSetClient(host, STHostResolveCallback, &context)
        // Schedule the host with the current run loop
        CFHostScheduleWithRunLoop(host, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        // Start host info resolution (address resolution)
        success = CFHostStartInfoResolution(host, .addresses, &streamError)
        
        if !success {
            didFailWithHostStreamError(streamError)
        }
    }
    
    func stop() {
        // Placeholder for stopping the ping.
        self.stopHostResolution()
        self.stopSocket()
        self.ipAddress = nil;
        self.hostAddress = nil;
    }
    func stopHostResolution() {
        // Shut down the CFHost.
        if let host = self.host {
            CFHostSetClient(host, nil, nil)  // Remove the client callback
            CFHostUnscheduleFromRunLoop(host, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)  // Unschedule from the current run loop
            self.host = nil  // Set the host to nil after stopping the resolution
        }
    }
    func sendPacket(_ packet: Data) {
        var err: Int32 = 0
        var bytesSent: ssize_t = -1
        let strongDelegate = delegate
        
        // Send the packet
        if socket == nil {
            bytesSent = -1
            err = EBADF
        } else {
            pingStartDate = Date()
            bytesSent = packet.withUnsafeBytes { packetBytes in
                hostAddress?.withUnsafeBytes { hostBytes in
                    guard let packetBase = packetBytes.baseAddress,
                          let hostBase = hostBytes.baseAddress else {
                        return -1
                    }
                    return sendto(
                        CFSocketGetNative(socket),
                        packetBase,
                        packet.count,
                        0,
                        hostBase.assumingMemoryBound(to: sockaddr.self),
                        socklen_t(hostAddress?.count ?? 0)
                    )
                } ?? 0
            }
            if bytesSent < 0 {
                err = errno
            }
        }
        
        // Handle the results of the send
        if bytesSent > 0 && bytesSent == packet.count {
            // Complete success. Notify the delegate.
            strongDelegate?.simplePing(self, didSendPacket: packet, sequenceNumber: nextSequenceNumber)
        } else {
            // Some sort of failure. Notify the delegate.
            if err == 0 {
                err = ENOBUFS // No buffer space available
            }
            let error = NSError(domain: NSPOSIXErrorDomain, code: Int(err), userInfo: nil)
            strongDelegate?.simplePing(self, didFailToSendPacket: packet, sequenceNumber: nextSequenceNumber, error: error)
        }
        
        // Update sequence number
        nextSequenceNumber += 1
        if nextSequenceNumber == 0 {
            nextSequenceNumberHasWrapped = true
        }
    }
    
    func packetWithPingData(_ data: Data?) -> Data? {
        // Ensure host address is not nil
        guard let hostAddress = self.hostAddress else {
            assertionFailure("Host address must not be nil. Ensure -simplePing:didStartWithAddress: is called first.")
            return nil
        }
        
        var payload = data
        
        // Construct default payload if data is nil
        if payload == nil {
            let sequenceNumber = 99 - (self.nextSequenceNumber % 100)
            if let dummyPayload = String(format: "%28zd bottles of beer on the wall", sequenceNumber)
                .data(using: .ascii) {
                payload = dummyPayload
                
                // Assert payload length to ensure a 64-byte ICMP packet (including header)
                assert(payload?.count == 56, "Payload size is incorrect, expected 56 bytes.")
            }
        }
        
        // Ensure payload is not nil at this point
        guard let payload = payload else {
            assertionFailure("Payload creation failed.")
            return nil
        }
        
        // Construct the ping packet based on the host address family
        let packet: Data?
        switch Int32(self.hostAddressFamily) {
        case AF_INET:
            packet = self.pingPacket(type: STICMPv4Type.echoRequest.rawValue, payload: payload, requiresChecksum: true)
        case AF_INET6:
            packet = self.pingPacket(type: STICMPv6Type.echoRequest.rawValue, payload: payload, requiresChecksum: false)
        default:
            assertionFailure("Unknown host address family.")
            return nil
        }
        
        assert(packet != nil, "Packet creation failed.")
        return packet
    }
    func icmpHeaderOffsetInIPv4Packet(_ packet: Data, timeToLive: inout Int) -> Int? {
        // Returns the offset of the ICMPv4Header within an IP packet.
        
        var result: Int? = nil
        
        if packet.count >= MemoryLayout<STIPv4Header>.size + MemoryLayout<STICMPHeader>.size {
            let ipPtr = packet.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> UnsafePointer<STIPv4Header> in
                return bytes.bindMemory(to: STIPv4Header.self).baseAddress!
            }
            
            // Check if it's IPv4 and the protocol is ICMP
            if (ipPtr.pointee.versionAndHeaderLength & 0xF0) == 0x40 && ipPtr.pointee.protocol == IPPROTO_ICMP {
                let ipHeaderLength = (Int(ipPtr.pointee.versionAndHeaderLength) & 0x0F) * MemoryLayout<UInt32>.size
                if packet.count >= ipHeaderLength + MemoryLayout<STICMPHeader>.size {
                    result = ipHeaderLength
                }
            }
            
            // Set the timeToLive if requested
            timeToLive = Int(ipPtr.pointee.timeToLive)
        }
        
        return result
    }
    
    func validateSequenceNumber(_ sequenceNumber: UInt16) -> Bool {
        if nextSequenceNumberHasWrapped {
            // If the sequence numbers have wrapped that we can't reliably check
            // whether this is a sequence number we sent. Rather, we check to see
            // whether the sequence number is within the last 120 sequence numbers
            // we sent. Note that the UInt16 subtraction here does the right thing regardless of the wrapping.
            //
            // Why 120? Well, if we send one ping per second, 120 is 2 minutes, which
            // is the standard "max time a packet can bounce around the Internet" value.
            return (nextSequenceNumber - sequenceNumber) < 120
        } else {
            return sequenceNumber < nextSequenceNumber
        }
    }
    func validatePing4ResponsePacket(_ packet: NSMutableData, sequenceNumberPtr: inout UInt16, timeToLive: inout Int) -> Bool {
        var result = false
        var icmpHeaderOffset: Int
        var icmpPtr: UnsafeMutablePointer<STICMPHeader>?
        var receivedChecksum: UInt16
        var calculatedChecksum: UInt16
        
        // 获取 ICMP 头部的偏移量
        icmpHeaderOffset = self.icmpHeaderOffsetInIPv4Packet(packet.copy() as! Data, timeToLive: &timeToLive) ?? 0
        if icmpHeaderOffset != NSNotFound {
            // 获取 ICMP 头部指针
            icmpPtr = UnsafeMutablePointer<STICMPHeader>(mutating: packet.mutableBytes.advanced(by: icmpHeaderOffset).assumingMemoryBound(to: STICMPHeader.self))
            
            // 获取并计算校验和
            receivedChecksum = icmpPtr!.pointee.checksum
            icmpPtr!.pointee.checksum = 0
            calculatedChecksum = st_in_cksum(buffer: icmpPtr!, bufferLen: packet.length - icmpHeaderOffset)
            icmpPtr!.pointee.checksum = receivedChecksum
            
            // 校验和匹配
            if receivedChecksum == calculatedChecksum {
                // 校验 ICMP 类型和代码
                if icmpPtr!.pointee.type == STICMPv4Type.echoReply.rawValue && icmpPtr!.pointee.code == 0 {
                    if _OSSwapInt16(icmpPtr!.pointee.identifier) == identifier {
                        // 获取并校验序列号
                        let sequenceNumber = _OSSwapInt16(icmpPtr!.pointee.sequenceNumber)
                        if validateSequenceNumber(sequenceNumber) {
                            // 移除 IPv4 头部
                            packet.replaceBytes(in: NSRange(location: 0, length: icmpHeaderOffset), withBytes: nil, length: 0)
                            // 设置返回的序列号
                            sequenceNumberPtr = sequenceNumber
                            result = true
                        }
                    }
                }
            }
        }
        
        return result
    }
    func validatePing6ResponsePacket(packet: NSMutableData, sequenceNumberPtr: inout UInt16) -> Bool {
        var result = false
        
        if packet.length >= MemoryLayout<STICMPHeader>.size {
            let icmpPtr = packet.bytes.assumingMemoryBound(to: STICMPHeader.self)
            
            // In the IPv6 case we don't check the checksum because that's hard (we need to
            // cook up an IPv6 pseudo header and we don't have the ingredients) and unnecessary
            // (the kernel has already done this check).
            
            if icmpPtr.pointee.type == STICMPv6Type.echoReply.rawValue && icmpPtr.pointee.code == 0 {
                if _OSSwapInt16(icmpPtr.pointee.identifier) == self.identifier {
                    var sequenceNumber: UInt16
                    sequenceNumber = _OSSwapInt16(icmpPtr.pointee.sequenceNumber)
                    if validateSequenceNumber(sequenceNumber) {
                        sequenceNumberPtr = sequenceNumber
                        result = true
                    }
                }
            }
        }
        
        return result
    }
    func validatePingResponsePacket(packet: NSMutableData, sequenceNumberPtr: inout UInt16, timeToLive: inout Int) -> Bool {
        var result = false
        
        switch Int32(self.hostAddressFamily) {
        case AF_INET:
            result = validatePing4ResponsePacket(packet, sequenceNumberPtr: &sequenceNumberPtr, timeToLive: &timeToLive)
        case AF_INET6:
            result = validatePing6ResponsePacket(packet: packet, sequenceNumberPtr: &sequenceNumberPtr)
        default:
            assertionFailure("Unexpected address family")
            result = false
        }
        
        return result
    }
    
    func readData() {
        var err:Int;
        let kBufferSize = 65535 // Maximum IP packet size
        
        var buffer: UnsafeMutableRawPointer? = malloc(kBufferSize)
        assert(buffer != nil, "Failed to allocate buffer")
        
        var addr = sockaddr_storage()
        var addrLen: socklen_t = socklen_t(MemoryLayout<sockaddr_storage>.size)
        var bytesRead: ssize_t = 0
        
        // Assuming self.socket is a valid CFSocket and we are converting it to a native socket descriptor.
        if let socket = self.socket {
            // Cast the sockaddr_storage to sockaddr to pass it to recvfrom
            bytesRead = recvfrom(CFSocketGetNative(socket), buffer, kBufferSize, 0,
                                 unsafeBitCast(addr, to: UnsafeMutablePointer<sockaddr>.self), &addrLen)
        } else {
            print("Socket is invalid or nil.")
        }
        err = 0
        if bytesRead < 0{
            err = Int(errno)
        }
        //Process the data we read.
        if bytesRead > 0 {
            let packet = NSMutableData(bytes: buffer!, length: Int(bytesRead))
            assert(packet != nil)
            
            // We got some data, pass it up to our client.
            var sequenceNumber: UInt16 = 0
            var timeToLive: Int = 0
            
            let strongDelegate = self.delegate
            if validatePingResponsePacket(packet: packet, sequenceNumberPtr: &sequenceNumber, timeToLive: &timeToLive) {
                if let delegate = strongDelegate{
                    let timeElapsed = Date().timeIntervalSince(self.pingStartDate)
                    //                    delegate.st_simplePing(self, didReceivePingResponsePacket: packet as! Data, timeToLive: timeToLive, sequenceNumber: sequenceNumber, timeElapsed: timeElapsed)
                    delegate.simplePing(self, didReceivePingResponsePacket: packet.copy() as! Data,timeToLive: timeToLive,sequenceNumber: sequenceNumber,timeElapsed: timeElapsed)
                }
            } else {
                if let delegate = strongDelegate{
                    delegate.simplePing(self, didReceiveUnexpectedPacket: packet.copy() as! Data)
                }
            }
        } else {
            // We failed to read the data, so shut everything down.
            if err == 0 {
                err = Int(EPIPE)
            }
            didFailWithError(NSError(domain: NSPOSIXErrorDomain, code: Int(err), userInfo: nil))
        }
        
        free(buffer)
        
        // Note that we don't loop back trying to read more data. Rather, we just
        // let CFSocket call us again.
    }
    
    func stopSocket(){
        if let soc = self.socket {
            CFSocketInvalidate(soc)
            self.socket = nil
        }
    }
    func hostResolutionDone() {
        var resolved:DarwinBoolean = false
        let  resolveDrawinPonter:UnsafeMutablePointer<DarwinBoolean>?  = UnsafeMutablePointer(&resolved)
        var addresses: [Data]?
        guard let  host = self.host ,let addressing = CFHostGetAddressing(host, resolveDrawinPonter)  else{
            print("some thing error")
            return
        }
        addresses = addressing.takeUnretainedValue() as? [Data]
        
        // Find the irst appropriate address.
        if resolved.boolValue, let addresses = addresses {
            resolved = false
            for address in addresses {
                let addrPtr = address.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> UnsafePointer<sockaddr> in
                    return pointer.baseAddress!.assumingMemoryBound(to: sockaddr.self)
                }
                
                if address.count >= MemoryLayout<sockaddr>.size {
                    var s: UnsafeMutablePointer<CChar>?
                    switch addrPtr.pointee.sa_family {
                    case sa_family_t(AF_INET):
                        var addr_in = addrPtr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
                        s = UnsafeMutablePointer<CChar>.allocate(capacity: Int(INET_ADDRSTRLEN))
                        inet_ntop(AF_INET, &addr_in.sin_addr, s, socklen_t(INET_ADDRSTRLEN))
                        self.ipAddress = String(cString: s!)
                        if self.addressStyle != .icmpv6 {
                            self.hostAddress = address
                            resolved = true
                        }
                        
                    case sa_family_t(AF_INET6):
                        var addr_in6 = addrPtr.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { $0.pointee }
                        s = UnsafeMutablePointer<CChar>.allocate(capacity: Int(INET6_ADDRSTRLEN))
                        inet_ntop(AF_INET6, &addr_in6.sin6_addr, s, socklen_t(INET6_ADDRSTRLEN))
                        self.ipAddress = String(cString: s!)
                        if self.addressStyle != .icmpv4 {
                            self.hostAddress = address
                            resolved = true
                        }
                        
                    default:
                        break
                    }
                    
                    s?.deallocate()
                }
                
                if resolved.boolValue {
                    break
                }
            }
        }
        
        // Done resolving, shut that down.
        stopHostResolution()
        
        // If all is OK, start the send/receive infrastructure, otherwise stop.
        if resolved.boolValue {
            startWithHostAddress()
        } else {
            didFailWithError(NSError(domain: kCFErrorDomainCFNetwork as String,
                                     code:Int(HOST_NOT_FOUND),
                                     userInfo: nil))
        }
    }
    deinit{
        self.stop()
    }
}


