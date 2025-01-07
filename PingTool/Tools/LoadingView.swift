//
//  LoadingView.swift
//  demopackage
//
//  Created by work on 2024/12/17.
//

import Foundation
import SwiftUI
struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                 ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(2)
                .frame(width: 80, height: 80)
                .background(Color.black.opacity(0.75))
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
}
