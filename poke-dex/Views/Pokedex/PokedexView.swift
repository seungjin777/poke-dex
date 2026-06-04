import SwiftUI
import Kingfisher
import SwiftData

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
                    // 기본: 세대 카드 목록
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
                    // 검색 결과 목록 - 클릭할 때만 이동
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
                    // 검색 결과 없을 때
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
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.15))
                .frame(height: 100)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(generation.name) 지방")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.primary)
                    
                    Text("\(generation.range.count)마리")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                
                Spacer()
                
                KFImage(URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(generation.range.lowerBound).png"))
                    .placeholder {
                        ProgressView()
                            .frame(width: 80, height: 80)
                    }
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .padding(.trailing)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PokedexView()
}
