import SwiftUI
import Kingfisher
import SwiftData

// 세대별 스타팅 포켓몬 3마리 ID (비크티니 제외한 실제 스타팅 기준)
let generationStarters: [Int: [Int]] = [
    1: [1, 4, 7],       // 이상해씨, 파이리, 꼬부기
    2: [152, 155, 158], // 치코리타, 브케인, 리아코
    3: [252, 255, 258], // 나무지기, 아차모, 물짱이
    4: [387, 390, 393], // 모부기, 불꽃숭이, 팽도리
    5: [495, 498, 501], // 주리비얀, 챠오꿈, 오샤왓 (비크티니 제외)
    6: [650, 653, 656], // 도치마론, 푸호꼬, 개굴닌자
    7: [722, 725, 728], // 나몰빼미, 냐오불, 물범벨
    8: [810, 813, 816], // 흥나숭, 염버니, 울머기
    9: [906, 909, 912]  // 나오하, 뜨아거, 꾸아꾸아
]

struct PokedexView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query private var cachedPokemons: [CachedPokemon]
    
    @State private var searchText = ""
    
    // 캐시된 포켓몬 중 검색어와 매칭되는 결과
    var searchResults: [CachedPokemon] {
        guard !searchText.isEmpty else { return [] }
        return cachedPokemons.filter {
            $0.koreanName.contains(searchText) ||
            String($0.id).contains(searchText)
        }
        .sorted { $0.id < $1.id }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(generations, id: \.id) { generation in
                                NavigationLink(destination: GenerationPokemonListView(generation: generation)) {
                                    GenerationCardView(generation: generation)
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    List(searchResults) { pokemon in
                        NavigationLink(destination: PokedexDetailView(pokemonId: pokemon.id)) {
                            HStack {
                                KFImage(URL(string: pokemon.imageUrl))
                                    .placeholder { ProgressView().frame(width: 50, height: 50) }
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("No.\(String(format: "%04d", pokemon.id))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(pokemon.koreanName)
                                }
                            }
                        }
                    }
                    .overlay {
                        if searchResults.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.gray)
                                Text("검색 결과가 없어요")
                                    .foregroundStyle(.secondary)
                                Text("도감을 먼저 열어서 데이터를 불러와주세요")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("도감")
            .searchable(text: $searchText, prompt: "포켓몬 이름 또는 번호 검색")
        }
    }
}

struct GenerationCardView: View {
    let generation: Generation
    
    // 해당 세대 스타팅 3마리 이미지 URL
    var starterImageUrls: [String] {
        let ids = generationStarters[generation.id] ?? [generation.range.lowerBound]
        return ids.map {
            "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\($0).png"
        }
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.15))
                .frame(height: 110)
            
            HStack(spacing: 0) {
                // 세대 정보 (좌측)
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(generation.name) 지방")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.primary)
                    Text("\(generation.range.count)마리")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.leading)
                
                Spacer()
                
                // 스타팅 3마리 이미지 (우측, 살짝 겹치게)
                ZStack {
                    ForEach(Array(starterImageUrls.enumerated()), id: \.offset) { index, urlString in
                        KFImage(URL(string: urlString))
                            .placeholder { Color.clear.frame(width: 70, height: 70) }
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            // 뒤로 갈수록 오른쪽에 위치, 앞 이미지가 위에 겹침
                            .offset(x: CGFloat(index - 1) * 45)
                            .zIndex(Double(index))// 첫 번째가 제일 앞
                    }
                }
                .frame(width: 70 + 44 * 2) // 3마리 겹친 전체 너비
                .padding(.trailing, 8)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PokedexView()
}
