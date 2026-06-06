import SwiftUI
import SwiftData
import Kingfisher

struct GenerationPokemonListView: View {
    
    let generation: Generation
    
    @Environment(\.modelContext) private var modelContext
    
    // 커스텀 검색창 HStack 앞에 뒤로가기 버튼 추가
    @Environment(\.dismiss) private var dismiss
    
    @State private var pokemons: [Pokemon] = []
    @State private var isLoading = false
    @State private var loadedCount = 0
    @State private var searchText = ""
    @State private var isLampBlinking = false
    @FocusState private var isSearchFocused: Bool
    
    var isFullyLoaded: Bool {
        pokemons.count >= generation.range.count
    }
    
    var filteredPokemons: [Pokemon] {
        guard !searchText.isEmpty else { return pokemons }
        return pokemons.filter {
            $0.koreanName.contains(searchText) ||
            String($0.id).contains(searchText)
        }
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
                    
                    Text("\(generation.name) 지방")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 14)
                
                // 검색창 HStack을 감싸는 HStack 추가
                HStack(spacing: 8) {
                    // 뒤로가기 버튼
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    // 기존 검색창
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.gray)
                        TextField("\(generation.name) 지방 포켓몬 검색", text: $searchText)
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
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
                
                // 첫 진입 로딩
                if pokemons.isEmpty && isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("첫 포켓몬 불러오는 중...")
                            .foregroundStyle(.white.opacity(0.8))
                            .font(.subheadline)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredPokemons) { pokemon in
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
                            .onAppear {
                                if pokemon.id == pokemons.last?.id && !isFullyLoaded && !isLoading {
                                    Task { await loadPokemons() }
                                }
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                blinkLamp()
                            })
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
                    .overlay {
                        if !searchText.isEmpty && filteredPokemons.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.white.opacity(0.6))
                                Text("'\(searchText)' 검색 결과 없음")
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 10).onChanged { _ in
                            isSearchFocused = false
                            blinkLamp()
                        }
                    )
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            blinkLamp()
        }
        .task {
            await loadPokemons()
        }
    }
    
    func loadPokemons() async {
        guard !isLoading && !isFullyLoaded else { return }
        isLoading = true
        
        let startId = (pokemons.last?.id ?? (generation.range.lowerBound - 1)) + 1
        let endId = generation.range.upperBound
        
        guard startId <= endId else {
            isLoading = false
            return
        }
        
        for id in startId...endId {
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

extension UINavigationController {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = nil
    }
}

#Preview {
    GenerationPokemonListView(generation: generations[0])
        .modelContainer(for: CachedPokemon.self, inMemory: true)
}
