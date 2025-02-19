//
//  IpPage.swift
//  PingTool
//
//  Created by work on 2024/12/30.
//

import Foundation
import Foundation
import SwiftUI
struct IpPage: View {
    @State var  localip:String = "0.0.0.0"
    @State var  outsideip:String = "0.0.0.0"
    @State var  outmaskip:String = "0.0.0.0";
    @State var  routerip:String = "0.0.0.0";
    fileprivate func fetchIpProcess() {
        localip  = PINGManagerTool.getLocalAddressIp() ?? "未获取到";
        PINGManagerTool.getPublicIPAddress(completion: { value in
            guard let aip = value else {
                DispatchQueue.main.async{
                    ToastManager.shared.show(message: "IP获取失败", type: .error)
                }
                return
            }
            DispatchQueue.main.async{
                outsideip = aip
            }
        })
        PINGManagerTool.getSubnetMask { value in
            guard let submask = value else {
                DispatchQueue.main.async{
                    ToastManager.shared.show(message: "子网掩码获取失败", type: .error)
                }
                return
            }
            DispatchQueue.main.async{
                outmaskip = submask
            }
        }
        routerip =  PINGManagerTool.getDefaultGateway() ?? "empty"
        
    }
    
    var body: some View {
        ItemCardContainer(content: {
            VStack(alignment: .leading, spacing: 10, content: {
                HStack{
                    Text("本地IP地址: ").itemLarge()
                    Text(localip).itemMedium()
                }
                HStack{
                    Text("外网IP地址: ").itemLarge()
                    Text(outsideip).itemMedium()
                }
                HStack{
                    Text("子网掩码: ").itemLarge()
                    Text(outmaskip).itemMedium()
                }
                HStack{
                    Text("路由器地址: ").itemLarge()
                    Text(routerip).itemMedium()
                }
                
                
            })
            .onAppear{
                fetchIpProcess()
            }
        })
        .animation(.spring)
        .padding(EdgeInsets(top: 50, leading: 0, bottom: 0, trailing: 0))
        .removeBar()
        
        
    }
}

#Preview {
    IpPage()
}
