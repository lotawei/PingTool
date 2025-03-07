//
//  IpInfo.swift
//  PingTool
//
//  Created by work on 2025/3/6.
//

import SwiftUI
import MapKit

// IP信息模型
struct IPInfo:Codable {
    var localip: String = "Loading..."
    var pubip: String = "Loading..."
    var country: String = "--"
    var region: String = "--"
    var city: String = "--"
    var isp: String = "--"
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var timezone: String = "--"
    var asNumber: String = "--"
    var organization: String = "--"
    var connectionType: String = "--"
    
    // 初始化方法
    init() {}
    
    // 使用参数初始化
    init(ipv4: String, ipv6: String, country: String, region: String, city: String,
         isp: String, latitude: Double, longitude: Double, timezone: String,
         asNumber: String = "--", organization: String = "--", connectionType: String = "--") {
        self.localip = ipv4
        self.pubip = ipv6
        self.country = country
        self.region = region
        self.city = city
        self.isp = isp
        self.latitude = latitude
        self.longitude = longitude
        self.timezone = timezone
        self.asNumber = asNumber
        self.organization = organization
        self.connectionType = connectionType
    }
}
