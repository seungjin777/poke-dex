import SwiftUI
import SwiftData
import Kingfisher

struct GenerationPokemonListView: View {
    
    let generation: Generation
    
    @Environment(\.modelContext) private var modelContext
    @State private var pokemons: [Pokemon] = []
    @State private var isLoading = false
    @State private var loadedCount = 0
    
    var body: some View {
        Group {
            if pokemons.isEmpty && isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("첫 포켓몬 불러오는 중...")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            } else {
                List(pokemons) { pokemon in
                    NavigationLink(destination: PokedexDetailView(pokemonId: pokemon.id)) {
                        HStack {
                            KFImage(URL(string: pokemon.imageUrl))
                                .placeholder {
                                    ProgressView()
                                        .frame(width: 50, height: 50)
                                }
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                            
                            VStack(alignment: .leading) {
                                Text("No.\(pokemon.id)")
                                    .foregroundStyle(.gray)
                                    .font(.caption)
                                Text(pokemon.koreanName)
                            }
                            
                            Spacer()
                            
                            if isLoading && pokemon.id == pokemons.last?.id {
                                HStack(spacing: 4) {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                    Text("\(loadedCount)/\(generation.range.count)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("\(generation.name) 지방")
        .task {
            await loadPokemons()
        }
    }
    
    func loadPokemons() async {
        guard pokemons.isEmpty else { return }
        isLoading = true
        
        for id in generation.range {
            do {
                let pokemon = try await PokeAPIService.shared.fetchPokemonWithCache(
                    id: id,
                    context: modelContext
                )
                await MainActor.run {
                    pokemons.append(pokemon)
                    loadedCount += 1
                }
            } catch {
                print("포켓몬 \(id) 로드 실패: \(error)")
            }
        }
        isLoading = false
    }
}

#Preview {
    GenerationPokemonListView(generation: generations[0])
        .modelContainer(for: CachedPokemon.self, inMemory: true)
}
