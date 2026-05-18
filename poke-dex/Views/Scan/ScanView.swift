//
//  ScanView.swift
//  poke-dex
//
//  Created by 승진 on 5/17/26.
//

import SwiftUI

// 포켓몬 스캔 화면
struct ScanView: View {
    var body: some View {
        NavigationStack {
            Text("포켓몬 스캔").navigationTitle("스캔") // 상단 타이틀
        }
    }
}

#Preview {
    PokedexView()
}
