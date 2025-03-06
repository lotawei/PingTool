//
//  ViewModel.swift
//  PingTool
//
//  Created by work on 2025/3/6.
//

import Foundation
import MapKit
import SwiftUI

class WhoIPViewModel: ObservableObject {
    @Published var ipInfo = IPInfo()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
    )
    
    private let pingManager = PINGManagerTool()
    
    func fetchIPInfo() {
        isLoading = true
        errorMessage = nil
        
        // 1. 获取本地IP
        if let localIP = PINGManagerTool.getLocalAddressIp() {
            self.ipInfo.localip = localIP
        }
        
        // 2. 获取公网IP
        PINGManagerTool.getPublicIPAddress { [weak self] publicIP in
            guard let self = self else { return }
            
            if let publicIP = publicIP {
                // 获取IP详细信息
                self.efetchIPDetails(ip: publicIP)
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "获取公网IP失败"
                }
            }
        }
    }

    private func efetchIPDetails(ip: String) {
        let urlString = "http://ip-api.com/json/\(ip)"
        guard let url = URL(string: urlString) else {
            self.errorMessage = "无效的URL"
            self.isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "没有收到数据"
                    return
                }
                
                // 打印原始 JSON 数据
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("收到的 JSON 数据：")
                    print(jsonString)
                    
                    // 格式化打印 JSON
                    if let jsonObject = try? JSONSerialization.jsonObject(with: data),
                       let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
                       let prettyString = String(data: prettyData, encoding: .utf8) {
                        print("\n格式化后的 JSON：")
                        print(prettyString)
                    }
                }
                
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode(IPApiResponse.self, from: data)
                    self.updateIPInfo(with: result)
                } catch {
                    self.errorMessage = "数据解析失败"
                }
            }
        }.resume()
    }
    
    private func updateIPInfo(with response: IPApiResponse) {
        ipInfo.pubip = response.query
        ipInfo.country = "\(response.country) (\(response.countryCode))"
        ipInfo.region = response.regionName
        ipInfo.city = "\(response.city) \(response.zip)"
        ipInfo.isp = response.isp
        ipInfo.timezone = response.timezone
        ipInfo.latitude = response.lat
        ipInfo.longitude = response.lon
        ipInfo.asNumber = response.as
        ipInfo.organization = response.org
        // 更新地图区域
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: response.lat,
                longitude: response.lon
            ),
            span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
        )
    }
}

// IP-API 响应模型
struct IPApiResponse: Codable {
    let status: String
    let country: String
    let countryCode: String
    let region: String
    let regionName: String
    let city: String
    let zip: String
    let lat: Double
    let lon: Double
    let timezone: String
    let isp: String
    let org: String
    let `as`: String
    let query: String // 公网地址IP
}
