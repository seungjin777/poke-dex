//
//  GenerationPokemonListView.swift
//  poke-dex
//
//  Created by 승진 on 5/21/26.
//

import SwiftUI
import SwiftData
import Kingfisher

struct GenerationPokemonListView: View {
    
    let generation: Generation
    
    @Environment(\.modelContext) private var modelContext
    @State private var pokemons: [Pokemon] = []
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("불러오는 중...")
            } else {
                List(pokemons) { pokemon in
                    NavigationLink(destination: PokemonDetailView(pokemonId: pokemon.id)) {
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
        isLoading = true
        do {
            pokemons = try await PokeAPIService.shared.fetchPokemonListWithCache(
                range: generation.range,
                context: modelContext
            )
        } catch {
            print("포켓몬 목록 로드 실패: \(error)")
        }
        isLoading = false
    }
}

#Preview {
    GenerationPokemonListView(generation: generations[0])
        .modelContainer(for: CachedPokemon.self, inMemory: true)
}
