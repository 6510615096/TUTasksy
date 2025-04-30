//
//  ContentView.swift
//  TUTasksy
//
//  Created by นางสาวณัฐภูพิชา อรุณกรพสุรักษ์ on 30/4/2568 BE.
//

import SwiftUI

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#") // ข้าม #
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        
        self.init(red: r, green: g, blue: b)
    }
}

struct ContentView: View {
    var body: some View {
        ZStack {
            Color(hex: "#CAE5FF")
                .scaledToFill()
                .ignoresSafeArea()
            Text("TU Student ID")
        }
    }
}

#Preview {
    ContentView()
}
