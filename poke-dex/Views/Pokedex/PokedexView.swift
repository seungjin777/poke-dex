//
//  PokedexView.swift
//  poke-dex
//
//  Created by 승진 on 5/17/26.
//

import SwiftUI

struct PokedexView: View {
    
    // @State: 값이 바뀌면 화면을 자동으로 다시 그려줌
    @State private var pokemons: [Pokemon] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            
            if isLoading {
                // 로딩 중일 때 스피너 표시
                ProgressView("불러오는 중...")
            } else {
                List(pokemons) { pokemon in
                    NavigationLink(destination: PokemonDetailView(pokemon: pokemon)) {
                        HStack {
                            // AsyncImage: URL에서 이미지를 비동기로 불러옴
                            AsyncImage(url: URL(string: pokemon.imageUrl)) { image in
                                image.resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                            } placeholder: {
                                // 이미지 로딩 중일 때 표시
                                ProgressView()
                                    .frame(width: 50, height: 50)
                            }
                            
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
        .navigationTitle("도감")
        // 화면이 나타날 때 API 호출
        .task {
            await loadPokemons()
        }
    }
    
    func loadPokemons() async {
        isLoading = true
        do {
            pokemons = try await PokeAPIService.shared.fetchPokemonList()
        } catch {
            print("API 호출 실패: \(error)")
        }
        isLoading = false
    }
}

#Preview {
    PokedexView()
}
