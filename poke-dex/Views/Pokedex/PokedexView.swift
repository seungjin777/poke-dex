//
//  PokedexView.swift
//  poke-dex
//
//  Created by 승진 on 5/17/26.
//

import SwiftUI
import Kingfisher

struct PokedexView: View {
    var body: some View {
        NavigationStack {
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
            .navigationTitle("도감")
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
                
                // 세대 대표 이미지도 Kingfisher로 캐시 처리
                KFImage(URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(generation.range.lowerBound).png"))
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
