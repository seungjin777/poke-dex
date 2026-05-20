//
//  poke_dexApp.swift
//  poke-dex
//
//  Created by 승진 on 5/9/26.
//

import SwiftUI
import SwiftData

@main
struct poke_dexApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // SwiftData 컨테이너 등록
        .modelContainer(for: ScanHistory.self)
    }
}
