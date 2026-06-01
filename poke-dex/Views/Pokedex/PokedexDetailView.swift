//
//  PoekdexDetailView.swift
//  poke-dex
//
//  Created by 승진 on 5/17/26.
//

import SwiftUI
import SwiftData
import Kingfisher

struct PokedexDetailView: View {
    
    let pokemonId: Int
    
    @Environment(\.modelContext) private var modelContext
    @State private var pokemon: Pokemon?
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView("불러오는 중...")
                        .frame(maxHeight: .infinity)
                } else if let pokemon = pokemon {
                    
                    KFImage(URL(string: pokemon.imageUrl))
                        .placeholder {
                            ProgressView()
                                .frame(width: 200, height: 200)
                        }
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                    
                    Text("No.\(pokemon.id)")
                        .foregroundStyle(.gray)
                    
                    HStack {
                        ForEach(pokemon.types, id: \.self) { type in
                            Text(type)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(.blue.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(pokemon.description)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
            }
            .padding()
        }
        .navigationTitle(pokemon?.koreanName ?? "")
        .task {
            await loadPokemon()
        }
    }
    
    func loadPokemon() async {
        isLoading = true
        do {
            pokemon = try await PokeAPIService.shared.fetchPokemonWithCache(
                id: pokemonId,
                context: modelContext
            )
        } catch {
            print("포켓몬 로드 실패: \(error)")
        }
        isLoading = false
    }
}

#Preview {
    PokedexDetailView(pokemonId: 1)
}
