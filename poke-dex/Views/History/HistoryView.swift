import SwiftUI
import SwiftData

struct HistoryView: View {
    
    @Query(sort: \ScanHistory.date, order: .reverse) private var histories: [ScanHistory]
    @Environment(\.modelContext) private var modelContext
    
    @State private var searchText = ""
    @State private var sortOption: SortOption = .dateDesc
    @State private var isLampBlinking = false
    @FocusState private var isSearchFocused: Bool
    
    enum SortOption: String, CaseIterable {
        case dateDesc = "최신순"
        case dateAsc = "오래된순"
        case numberAsc = "번호순"
        case nameAsc = "이름순"
    }
    
    var filteredHistories: [ScanHistory] {
        let searched = searchText.isEmpty ? histories : histories.filter {
            $0.pokemonName.contains(searchText) ||
            String($0.pokemonNumber).contains(searchText)
        }
        switch sortOption {
        case .dateDesc:  return searched.sorted { $0.date > $1.date }
        case .dateAsc:   return searched.sorted { $0.date < $1.date }
        case .numberAsc: return searched.sorted { $0.pokemonNumber < $1.pokemonNumber }
        case .nameAsc:   return searched.sorted { $0.pokemonName < $1.pokemonName }
        }
    }
    
    func blinkLamp() {
        guard !isLampBlinking else { return }
        isLampBlinking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            isLampBlinking = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isLampBlinking = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isLampBlinking = false
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.894, green: 0.317, blue: 0.357)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // 상단 램프 영역
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color(red: isLampBlinking ? 0.267 : 0.29,
                                            green: isLampBlinking ? 0.906 : 0.56,
                                            blue: isLampBlinking ? 0.903 : 0.85))
                                .frame(width: 52, height: 52)
                                .overlay(Circle().stroke(.white, lineWidth: 3))
                                .animation(.easeInOut(duration: 0.1), value: isLampBlinking)
                            Circle()
                                .fill(.white.opacity(0.35))
                                .frame(width: 18, height: 18)
                                .offset(x: -8, y: -10)
                                .animation(.easeInOut(duration: 0.1), value: isLampBlinking)
                        }
                        
                        HStack(spacing: 7) {
                            ForEach([
                                (Color(red: 0.89, green: 0.29, blue: 0.29), "red"),
                                (Color(red: 0.96, green: 0.77, blue: 0.09), "yellow"),
                                (Color(red: 0.30, green: 0.69, blue: 0.31), "green")
                            ], id: \.1) { color, _ in
                                ZStack {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 14, height: 14)
                                        .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 1.5))
                                    Circle()
                                        .fill(.white.opacity(isLampBlinking ? 0.0 : 0.4))
                                        .frame(width: 5, height: 5)
                                        .offset(x: -2, y: -3)
                                        .animation(.easeInOut(duration: 0.1), value: isLampBlinking)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // 타이틀 + 정렬 버튼
                        HStack(spacing: 12) {
                            Text("My 히스토리")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            
                            Menu {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Button {
                                        sortOption = option
                                        blinkLamp()
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
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 32, height: 32)
                                    .background(.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 14)
                    
                    // 검색창
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.gray)
                        TextField("포켓몬 이름 또는 번호 검색", text: $searchText)
                            .focused($isSearchFocused)
                            .onSubmit {
                                isSearchFocused = false
                                blinkLamp()
                            }
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                isSearchFocused = false
                                blinkLamp()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                    .padding(10)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                    
                    // 콘텐츠 영역
                    if histories.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.white.opacity(0.6))
                            Text("촬영 기록이 없어요")
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        Spacer()
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
                                .simultaneousGesture(TapGesture().onEnded {
                                    blinkLamp()
                                })
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    modelContext.delete(filteredHistories[index])
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal, 4)
                        .padding(.bottom, 4)
                        .overlay {
                            if !searchText.isEmpty && filteredHistories.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.white.opacity(0.6))
                                    Text("'\(searchText)' 검색 결과 없음")
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                            }
                        }
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 10).onChanged { _ in
                                isSearchFocused = false
                                blinkLamp()
                            }
                        )
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                blinkLamp()
            }
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: ScanHistory.self, inMemory: true)
}
