//
//  PingViewModel.swift
//  PingTool
//
//  Created by work on 2025/3/7.
//
import SwiftUI
import  Combine
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
