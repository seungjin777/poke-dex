//
//  ScanView.swift
//  poke-dex
//
//  Created by 승진 on 5/17/26.
//

import SwiftUI

// 히스토리 화면
struct HistoryView: View {
    var body: some View {
        NavigationStack {
            Text("히스토리").navigationTitle("히스토리") // 상단 타이틀
        }
    }
}

#Preview {
    PokedexView()
}
