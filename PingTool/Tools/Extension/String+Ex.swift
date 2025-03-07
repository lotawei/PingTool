//
//  String+Ex.swift
//  PingTool
//
//  Created by work on 2025/2/5.
//

import Foundation
import SwiftUI
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
    
    /// 根据网速值返回对应的颜色和描述
    static func getNetworkInfo(for value: Double) -> (color: Color, description: String) {
        switch value {
        case ..<0.1:
            return (Color(hex: "#FF4B4B"), "网络丢失或不可用 (0Mbps)")
        case 0.1..<5:
            return (Color(hex: "#FFA500"), "网速较慢 (0.1-5Mbps)")
        case 5..<10:
            return (Color(hex: "#2ECC71"), "网速良好 (5-10Mbps)")
        case 10..<20:
            return (Color(hex: "#3498DB"), "网速优秀 (10-20Mbps)")
        default:
            return (Color(hex: "#9B59B6"), "网速极快 (>20Mbps)")
        }
    }
    
}
