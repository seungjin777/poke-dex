import SwiftUI
import SwiftData

struct HistoryView: View {
    
    @Query(sort: \ScanHistory.date, order: .reverse) private var histories: [ScanHistory]
    @Environment(\.modelContext) private var modelContext
    
    @State private var searchText = ""
    @State private var sortOption: SortOption = .dateDesc
    
    enum SortOption: String, CaseIterable {
        case dateDesc = "최신순"
        case dateAsc = "오래된순"
        case numberAsc = "번호순"
        case nameAsc = "이름순"
    }
    
    // 검색 + 정렬 적용
    var filteredHistories: [ScanHistory] {
        let searched = searchText.isEmpty ? histories : histories.filter {
            $0.pokemonName.contains(searchText) ||
            String($0.pokemonNumber).contains(searchText)
        }
        
        switch sortOption {
        case .dateDesc:
            return searched.sorted { $0.date > $1.date }
        case .dateAsc:
            return searched.sorted { $0.date < $1.date }
        case .numberAsc:
            return searched.sorted { $0.pokemonNumber < $1.pokemonNumber }
        case .nameAsc:
            return searched.sorted { $0.pokemonName < $1.pokemonName }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if histories.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.gray)
                        Text("촬영 기록이 없어요")
                            .foregroundStyle(.gray)
                    }
                } else {
                    List {
                        ForEach(filteredHistories) { history in
                            NavigationLink(destination: HistoryScanDetailView(history: history)) {
                                HStack {
                                    if let uiImage = UIImage(data: history.imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("No.\(String(format: "%04d", history.pokemonNumber))")
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
                        .onDelete { indexSet in
                            // filteredHistories 기준 삭제
                            for index in indexSet {
                                modelContext.delete(filteredHistories[index])
                            }
                        }
                    }
                    // 검색창
                    .searchable(text: $searchText, prompt: "포켓몬 이름 또는 번호 검색")
                }
            }
            .navigationTitle("히스토리")
            // 정렬 메뉴
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                sortOption = option
                            } label: {
                                HStack {
                                    Text(option.rawValue)
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: ScanHistory.self, inMemory: true)
}
