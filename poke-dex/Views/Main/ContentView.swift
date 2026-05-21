//
//  ContentView.swift
//  poke-dex
//
//  Created by 승진 on 5/9/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            PokedexView()
                .tabItem {
                    Label("도감", systemImage: "book.fill")
                }
            
            ScanView()
                .tabItem {
                    Label("스캔", systemImage: "camera.fill")
                }
            
            HistoryView()
                .tabItem {
                    // clock.fill이 올바른 아이콘 이름 (clocks.fill은 존재하지 않음)
                    Label("히스토리", systemImage: "clock.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
