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
        // CachedPokemon 추가
        .modelContainer(for: [ScanHistory.self, CachedPokemon.self])
    }
}
