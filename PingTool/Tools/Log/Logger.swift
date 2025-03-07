//
//  Logger.swift
//  PingTool
//
//  Created by work on 2025/1/3.
//
import Foundation
class Logger {
    
    // 静态方法打印 Debug 日志
    static func debug(_ message: String, function: String = #function, line: Int = #line) {
        #if DEBUG
        let file = (function as NSString).lastPathComponent
        print("[DEBUG] *func*\(file) - *line*\(line): \(message)")
        #endif
    }
    
    // 静态方法打印 Error 日志
    static func error(_ message: String, function: String = #function, line: Int = #line) {
        #if DEBUG
        let file = (function as NSString).lastPathComponent
        print("[ERROR] *func*\(file) - *line*\(line): \(message)")
        #else
        // 在 Release 模式下，可以不打印错误日志，或者你可以选择记录到文件
        // print("[ERROR] *func*\(file) - *line*\(line): \(message)")
        #endif
    }
    
    // 静态方法打印 Info 日志
    static func info(_ message: String, function: String = #function, line: Int = #line) {
        #if DEBUG
        let file = (function as NSString).lastPathComponent
        print("[INFO] *func*\(file) - *line*\(line): \(message)")
        #endif
    }
    
    // 静态方法打印 Warning 日志
    static func warning(_ message: String, function: String = #function, line: Int = #line) {
        #if DEBUG
        let file = (function as NSString).lastPathComponent
        print("[WARNING] *func*\(file) - *line*\(line): \(message)")
        #endif
    }
}
