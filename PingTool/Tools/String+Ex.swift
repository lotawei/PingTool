//
//  String+Ex.swift
//  PingTool
//
//  Created by work on 2025/2/5.
//

import Foundation
extension String{
    // 格式化下载速度
    static func formatSpeed(speed: Double) -> String {
        // 将速度格式化为可读的字符串
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        let formattedSpeed = formatter.string(fromByteCount: Int64(speed))
        return "\(formattedSpeed)/s"
    }
    // mb
    static func formatMBPerSecond(speed: Double) -> String {
        let speedInMB = speed / (1024 * 1024) // 转换为 MB
        return String(format: "%.2f MB/s", speedInMB) // 格式化为两位小数的 MB/s
    }
    // mb
    static func formatMBPerSecond(speed: Double) -> Double {
        let speedInMB = speed / (1024 * 1024) // 转换为 MB
        return speedInMB
    }
    
    // Mbps
    static func formatKMBPerSecond(speed: Double) -> Double {
        let speedInKMB = (speed / (1024 * 1024) ) * 8
        return speedInKMB
    }
    
}
