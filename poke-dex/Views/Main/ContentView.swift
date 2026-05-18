//
//  ContentView.swift
//  poke-dex
//
//  Created by 승진 on 5/9/26.
//

import SwiftUI

struct ContentView: View {
        
    // 이 화면에 표시될 UI정읜
    var body: some View {
        
        //탭 뷰 컨테이너
        TabView{
            PokedexView().tabItem {
                Label("도감", systemImage: "book.fill")
            }
            
            ScanView().tabItem {
                Label("스캔", systemImage: "camera.fill")
            }
            
            HistoryView().tabItem{
                Label("히스토리", systemImage: "clocks.fill")
            }
        }
        
    }
    
}

#Preview {
    ContentView()
}
