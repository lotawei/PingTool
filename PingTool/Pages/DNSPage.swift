//
//  IpPage.swift
//  PingTool
//
//  Created by work on 2024/12/30.
//

import Foundation
import SwiftUI
struct DNSPage: View {
    @State var  dnsIp:String = "0.0.0.0"
    fileprivate func fetchDNSProcess() {
        PINGManagerTool.fetchDNSServers(completion: { servers in
                
            if(servers.count == 0){
                DispatchQueue.main.async{
                        ToastManager.shared.show(message: "IP获取失败", type: .error)
                    }
            }else{
                DispatchQueue.main.async{
                    dnsIp = servers.joined(separator: "\n")
                }
            }
          
        })
    }
    
    var body: some View {
        ItemCardContainer(content:{
                VStack(alignment: .leading, content: {
                    HStack{
                        Text("NDS地址: ").itemLarge()
                        Text(dnsIp).itemMedium()
                    }
                    
                })
                .onAppear{
                    fetchDNSProcess()
                }
            })
        .padding(EdgeInsets(top: 50, leading: 0, bottom: 0, trailing: 0))
        .animation(.spring)
        .removeBar()
        
    }
}

#Preview {
    DNSPage()
}
