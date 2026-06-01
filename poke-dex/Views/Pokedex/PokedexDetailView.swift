import SwiftUI
import SwiftData
import Kingfisher

struct PokedexDetailView: View {
    
    let pokemonId: Int
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allHistories: [ScanHistory]
    
    @State private var pokemon: Pokemon?
    @State private var isLoading = false
    
    // 해당 포켓몬 촬영 기록만 필터링
    var filteredHistories: [ScanHistory] {
        allHistories.filter { $0.pokemonNumber == pokemonId }
    }
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("불러오는 중...")
                    .padding(.top, 100)
            } else if let pokemon = pokemon {
                VStack(spacing: 0) {
                    
                    // 포켓몬 이미지
                    KFImage(URL(string: pokemon.imageUrl))
                        .placeholder { ProgressView().frame(width: 200, height: 200) }
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .padding(.top)
                    
                    // 도감 번호
                    Text("No.\(String(format: "%04d", pokemon.id))")
                        .foregroundStyle(.gray)
                        .font(.subheadline)
                    
                    // 타입
                    HStack {
                        ForEach(pokemon.types, id: \.self) { type in
                            Text(type)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(.blue.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // 키 / 몸무게
                    HStack(spacing: 32) {
                        VStack {
                            Text(String(format: "%.1fm", Double(pokemon.height) / 10))
                                .font(.headline)
                            Text("키")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        VStack {
                            Text(String(format: "%.1fkg", Double(pokemon.weight) / 10))
                                .font(.headline)
                            Text("몸무게")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // 설명
                    Text(pokemon.description)
                        .multilineTextAlignment(.center)
                        .padding()
                        .foregroundStyle(.secondary)
                    
                    Divider()
                    
                    // 특성 섹션
                    SectionHeader(title: "특성")
                    VStack(spacing: 8) {
                        ForEach(pokemon.abilities, id: \.name) { ability in
                            HStack {
                                Text(ability.name)
                                if ability.isHidden {
                                    Text("숨겨진 특성")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(.gray.opacity(0.2))
                                        .clipShape(Capsule())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider().padding(.top)
                    
                    // 스탯 섹션
                    SectionHeader(title: "스탯")
                    VStack(spacing: 8) {
                        ForEach(pokemon.stats, id: \.name) { stat in
                            HStack {
                                Text(stat.name)
                                    .frame(width: 70, alignment: .leading)
                                    .font(.subheadline)
                                Text("\(stat.value)")
                                    .frame(width: 35, alignment: .trailing)
                                    .font(.subheadline)
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(.gray.opacity(0.2))
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(statColor(value: stat.value))
                                            .frame(width: geo.size.width * CGFloat(stat.value) / 255)
                                    }
                                }
                                .frame(height: 8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider().padding(.top)
                    
                    // 진화 섹션
                    if !pokemon.evolutionChain.isEmpty {
                        SectionHeader(title: "진화")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(pokemon.evolutionChain.enumerated()), id: \.offset) { index, step in
                                    HStack(spacing: 4) {
                                        VStack {
                                            KFImage(URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(step.id).png"))
                                                .placeholder { ProgressView().frame(width: 70, height: 70) }
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 70, height: 70)
                                            Text("No.\(step.id)")
                                                .font(.caption2)
                                                .foregroundStyle(.gray)
                                        }
                                        if index < pokemon.evolutionChain.count - 1 {
                                            Image(systemName: "arrow.right")
                                                .foregroundStyle(.gray)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        Divider().padding(.top)
                    }
                    
                    // 촬영 기록 섹션
                    if !filteredHistories.isEmpty {
                        SectionHeader(title: "촬영 기록")
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(filteredHistories) { history in
                                if let uiImage = UIImage(data: history.imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 110)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
        }
        .navigationTitle(pokemon?.koreanName ?? "")
        .task {
            await loadPokemon()
        }
    }
    
    func statColor(value: Int) -> Color {
        switch value {
        case 0..<50: return .red
        case 50..<90: return .orange
        case 90..<120: return .yellow
        default: return .green
        }
    }
    
    func loadPokemon() async {
        isLoading = true
        do {
            pokemon = try await PokeAPIService.shared.fetchPokemon(id: pokemonId)
        } catch {
            print("포켓몬 로드 실패: \(error)")
        }
        isLoading = false
    }
}

// 섹션 헤더 공통 컴포넌트
struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.gray.opacity(0.1))
    }
}

#Preview {
    PokedexDetailView(pokemonId: 1)
}
