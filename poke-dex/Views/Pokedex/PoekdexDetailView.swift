//
//  PoekdexDetailView.swift
//  poke-dex
//
//  Created by 승진 on 5/17/26.
//

import SwiftUI

struct PokemonDetailView: View {
    
    let pokemon: Pokemon
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // 포켓몬 이미지
                AsyncImage(url: URL(string: pokemon.imageUrl)) { image in
                    image.resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                } placeholder: {
                    ProgressView()
                        .frame(width: 200, height: 200)
                }
                
                // 도감 번호
                Text("No.\(pokemon.id)")
                    .foregroundStyle(.gray)
                
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
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(pokemon.koreanName)
    }
}

#Preview {
    PokemonDetailView(pokemon: Pokemon(
        id: 1,
        name: "bulbasaur",
        koreanName: "이상해씨",
        description: "태어날 때부터 등에 이상한 씨앗이 심어져 있다.",
        imageUrl: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png",
        types: ["풀", "독"]
    ))
}
