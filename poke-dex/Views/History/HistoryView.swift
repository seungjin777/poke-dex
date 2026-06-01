//
//  ScanView.swift
//  poke-dex
//
//  Created by 승진 on 5/17/26.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    
    // SwiftData에서 히스토리 데이터 자동으로 불러오기
    @Query(sort: \ScanHistory.date, order: .reverse) private var histories: [ScanHistory]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            if histories.isEmpty {
                // 히스토리 없을 때
                VStack(spacing: 16) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.gray)
                    Text("촬영 기록이 없어요")
                        .foregroundStyle(.gray)
                }
            } else {
                List {
                    ForEach(histories) { history in
                        NavigationLink(destination: HistoryScanDetailView(history: history)) {
                            HStack {
                                // 촬영한 이미지
                                if let uiImage = UIImage(data: history.imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("No.\(history.pokemonNumber)")
                                        .foregroundStyle(.gray)
                                        .font(.caption)
                                    Text(history.pokemonName.isEmpty ? "이름 불러오는 중..." : history.pokemonName)
                                    Text(String(format: "신뢰도: %.1f%%", history.confidence * 100))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(history.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    // 스와이프로 삭제
                    .onDelete { indexSet in
                        for index in indexSet {
                            modelContext.delete(histories[index])
                        }
                    }
                }
            }
        }
        .navigationTitle("히스토리")
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: ScanHistory.self, inMemory: true)
}
