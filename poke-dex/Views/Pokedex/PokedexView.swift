import SwiftUI
import Kingfisher
import SwiftData

let generationStarters: [Int: [Int]] = [
    1: [1, 4, 7],
    2: [152, 155, 158],
    3: [252, 255, 258],
    4: [387, 390, 393],
    5: [495, 498, 501],
    6: [650, 653, 656],
    7: [722, 725, 728],
    8: [810, 813, 816],
    9: [906, 909, 912]
]

struct PokedexView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query private var cachedPokemons: [CachedPokemon]
    
    @State private var searchText = ""
    @State private var isLampBlinking = false
    @FocusState private var isSearchFocused: Bool
    
    var searchResults: [CachedPokemon] {
        guard !searchText.isEmpty else { return [] }
        return cachedPokemons.filter {
            $0.koreanName.contains(searchText) ||
            String($0.id).contains(searchText)
        }
        .sorted { $0.id < $1.id }
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
                        
                        Text("포켓몬 도감")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 14)
                    
                    // 커스텀 검색창
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
                    ScrollView {
                        VStack(spacing: 10) {
                            if searchText.isEmpty {
                                ForEach(generations, id: \.id) { generation in
                                    NavigationLink(destination: GenerationPokemonListView(generation: generation)) {
                                        GenerationCardView(generation: generation)
                                    }
                                    .simultaneousGesture(TapGesture().onEnded {
                                        blinkLamp()
                                    })
                                }
                            } else {
                                if searchResults.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 40))
                                            .foregroundStyle(.white.opacity(0.6))
                                        Text("검색 결과가 없어요")
                                            .foregroundStyle(.white.opacity(0.8))
                                        Text("도감을 먼저 열어서 데이터를 불러와주세요")
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.6))
                                    }
                                    .padding(.top, 60)
                                } else {
                                    ForEach(searchResults) { pokemon in
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
                                                        .foregroundStyle(.gray.opacity(0.7))
                                                    Text(pokemon.koreanName)
                                                        .foregroundStyle(.black)
                                                }
                                                Spacer()
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                        }
                                        .simultaneousGesture(TapGesture().onEnded {
                                            blinkLamp()
                                        })
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 10).onChanged { _ in
                            isSearchFocused = false
                            blinkLamp()
                        }
                    )
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                blinkLamp()
            }
        }
    }
}

struct GenerationCardView: View {
    let generation: Generation
    
    var starterImageUrls: [String] {
        let ids = generationStarters[generation.id] ?? [generation.range.lowerBound]
        return ids.map {
            "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\($0).png"
        }
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.847, green: 0.928, blue: 0.999))
            
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(generation.name) 지방")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(red: 0.076, green: 0.557, blue: 0.999))
                    Text("\(generation.range.count)마리")
                        .font(.subheadline)
                        .foregroundStyle(Color(red: 0.546, green: 0.788, blue: 1))
                }
                .padding(.leading, 16)
                
                Spacer()
                
                ZStack {
                    ForEach(Array(starterImageUrls.enumerated()), id: \.offset) { index, urlString in
                        KFImage(URL(string: urlString))
                            .placeholder { Color.clear.frame(width: 70, height: 70) }
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .offset(x: CGFloat(index - 1) * 45)
                            .zIndex(Double(index))
                    }
                }
                .frame(width: 70 + 44 * 2)
                .padding(.trailing, 8)
            }
            .padding(.vertical, 12)
        }
        .frame(height: 90)
        .buttonStyle(.plain)
    }
}

#Preview {
    PokedexView()
}
