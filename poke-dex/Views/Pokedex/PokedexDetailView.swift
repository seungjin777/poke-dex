import SwiftUI
import SwiftData
import Kingfisher
import AVFoundation

struct PokedexDetailView: View {
    
    let pokemonId: Int
    var autoReadDescription: Bool = false
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allHistories: [ScanHistory]
    
    @State private var pokemon: Pokemon?
    @State private var isLoading = false
    @State private var audioPlayer: AVPlayer?
    @State private var synthesizer = AVSpeechSynthesizer()
    
    // State 추가 (View 상단에)
    @State private var is3DPressed = false
    @State private var isCryPressed = false
    
    var filteredHistories: [ScanHistory] {
        allHistories.filter { $0.pokemonNumber == pokemonId }
    }
    
    func accentColor(opacity: Double = 0.15) -> Color {
        guard let firstType = pokemon?.types.first,
              let color = typeColors[firstType] else {
            return Color.gray.opacity(opacity)
        }
        return color.opacity(opacity)
    }
    
    @ViewBuilder
    func typeBackground(types: [String]) -> some View {
        let colors = types.compactMap { typeColors[$0] }
        
        if colors.count >= 2 {
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if let color = colors.first {
            LinearGradient(
                colors: [color, color.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Rectangle().fill(Color.gray.opacity(0.2))
        }
    }
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("불러오는 중...")
                    .padding(.top, 100)
            } else if let pokemon = pokemon {
                VStack(spacing: 0) {
                    
                    // 포켓몬 이미지 + 타입 컬러 배경
                    ZStack(alignment: .bottom) {
                        typeBackground(types: pokemon.types)
                            .frame(maxWidth: .infinity)
                            .frame(height: 430)
                        
                        VStack(spacing: 12) {
                            KFImage(URL(string: pokemon.imageUrl))
                                .placeholder { ProgressView().frame(width: 200, height: 200) }
                                .resizable()
                                .scaledToFit()
                                .frame(width: 220, height: 220)
                                .shadow(color: .black.opacity(0.6), radius: 5, y: 7)
                            
                            // 3D 보기 + 울음소리 버튼
                            HStack(spacing: 12) {
                                // 3D 버튼
                                NavigationLink(destination: PokemonModelView(
                                    pokemonId: pokemon.id,
                                    pokemonName: pokemon.koreanName,
                                    hasGenderDifferences: pokemon.hasGenderDifferences
                                )) {
                                    Label("3D로 보기", systemImage: "cube")
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(.white.opacity(0.25))
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(.white, lineWidth: 1.5))
                                        .shadow(color: .black.opacity(is3DPressed ? 0 : 0.3), radius: 4, x: 0, y: is3DPressed ? 0 : 4)
                                        .scaleEffect(is3DPressed ? 0.96 : 1.0)
                                }
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in withAnimation(.easeInOut(duration: 0.1)) { is3DPressed = true } }
                                        .onEnded { _ in withAnimation(.easeInOut(duration: 0.1)) { is3DPressed = false } }
                                )

                                // 울음소리 버튼
                                Button {
                                    playCry(pokemonId: pokemon.id)
                                } label: {
                                    Label("울음소리", systemImage: "speaker.wave.2.fill")
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(.white.opacity(0.25))
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(.white, lineWidth: 1.5))
                                        .shadow(color: .black.opacity(isCryPressed ? 0 : 0.3), radius: 4, x: 0, y: isCryPressed ? 0 : 4)
                                        .scaleEffect(isCryPressed ? 0.96 : 1.0)
                                }
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in withAnimation(.easeInOut(duration: 0.1)) { isCryPressed = true } }
                                        .onEnded { _ in withAnimation(.easeInOut(duration: 0.1)) { isCryPressed = false } }
                                )
                            }
                            .padding(.bottom, 35)
                        }
                    }
                    
                    // 상세정보 카드 영역 - 상단 모서리만 둥글게
                    VStack(spacing: 0) {

                        //포켓몬 이름 / 도감 번호
                        HStack(spacing: 10){
                            Text(pokemon.koreanName) //이름
                                .font(.title)
                                .bold()
                            
                            Text("No.\(String(format: "%04d", pokemon.id))") //번호
                                .foregroundStyle(.gray)
                                .font(.subheadline.italic())
                        
                        }.padding(.top, 16)
                    
                        // 타입 뱃지
                        HStack {
                            ForEach(pokemon.types, id: \.self) { type in
                                TypeBadgeView(typeName: type)
                            }
                        }.padding(8)
                        
                        // 키 / 몸무게 / 성별
                        HStack(spacing: 32) {
                            VStack {
                                Text(String(format: "%.1fm", Double(pokemon.height) / 10))
                                    .font(.headline)
                                Text("키")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            VStack {
                                Text(String(format: "%.1fkg", Double(pokemon.weight) / 10))
                                    .font(.headline)
                                Text("몸무게")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            VStack {
                                genderView(genderRate: pokemon.genderRate)
                                Text("성별")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                        
                        // 설명 + 음성 버튼
                        HStack(alignment: .top, spacing: 8) {
                            Text(pokemon.description)
                                .multilineTextAlignment(.leading)
                                .foregroundStyle(.secondary)
                            
                            Button {
                                readDescription(pokemon: pokemon)
                            } label: {
                                Image(systemName: synthesizer.isSpeaking ? "stop.circle.fill" : "speaker.wave.2.fill")
                                    .foregroundStyle(synthesizer.isSpeaking ? .red : .blue)
                                    .font(.title3)
                            }
                        }
                        .padding()
                        
                        Divider()
                        
                        // 특성 섹션
                        SectionHeader(title: "특성")
                        VStack(spacing: 8) {
                            ForEach(pokemon.abilities, id: \.name) { ability in
                                HStack {
                                    Text(ability.name)
                                    if ability.isHidden {
                                        Text("숨겨진 특성")
                                            .font(.caption)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(accentColor(opacity: 0.8))
                                            .clipShape(Capsule())
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(accentColor())
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        
                        Divider().padding(.top)
                        
                        // 스탯 섹션
                        SectionHeader(title: "스탯")
                        VStack(spacing: 8) {
                            ForEach(pokemon.stats, id: \.name) { stat in
                                HStack {
                                    Text(stat.name)
                                        .frame(width: 70, alignment: .leading)
                                        .font(.subheadline)
                                    Text("\(stat.value)")
                                        .frame(width: 35, alignment: .trailing)
                                        .font(.subheadline)
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(.gray.opacity(0.2))
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(statColor(value: stat.value))
                                                .frame(width: geo.size.width * CGFloat(stat.value) / 255)
                                        }
                                    }
                                    .frame(height: 8)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        Divider().padding(.top)
                        
                        // 진화 섹션
                        if let chain = pokemon.evolutionChain {
                            SectionHeader(title: "진화")
                            EvolutionTreeView(node: chain)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            Divider()
                        }
                        
                        // 촬영 기록 섹션
                        if !filteredHistories.isEmpty {
                            SectionHeader(title: "촬영 기록")
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 30) {
                                ForEach(filteredHistories) { history in
                                    if let uiImage = UIImage(data: history.imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 110)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                    .background(.white)
                    .clipShape(UnevenRoundedRectangle(
                        topLeadingRadius: 24,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 24
                    ))
                    .offset(y: -24)
                }
            }
        }
        .navigationTitle(pokemon?.koreanName ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadPokemon()
        }
        .onDisappear {
            synthesizer.stopSpeaking(at: .immediate)
        }
        .ignoresSafeArea(edges: .top)
    }
    
    func playCry(pokemonId: Int) {
        let urlString = "https://raw.githubusercontent.com/PokeAPI/cries/main/cries/pokemon/latest/\(pokemonId).ogg"
        if let url = URL(string: urlString) {
            audioPlayer = AVPlayer(url: url)
            audioPlayer?.play()
        }
    }
    
    @ViewBuilder
    func genderView(genderRate: Int) -> some View {
        switch genderRate {
        case -1:
            Image(systemName: "minus.circle")
                .foregroundStyle(.gray)
                .font(.headline)
        case 0:
            Text("♂")
                .foregroundStyle(.blue)
                .font(.headline)
        case 8:
            Text("♀")
                .foregroundStyle(.pink)
                .font(.headline)
        default:
            HStack(spacing: 2) {
                Text("♂").foregroundStyle(.blue)
                Text("♀").foregroundStyle(.pink)
            }
            .font(.headline)
        }
    }
    
    func statColor(value: Int) -> Color {
        switch value {
        case 0..<50: return .red
        case 50..<90: return .orange
        case 90..<120: return .yellow
        default: return .green
        }
    }
    
    func loadPokemon() async {
        isLoading = true
        do {
            pokemon = try await PokeAPIService.shared.fetchPokemon(id: pokemonId)
            if autoReadDescription, let pokemon = pokemon {
                readDescription(pokemon: pokemon)
            }
        } catch {
            print("포켓몬 로드 실패: \(error)")
        }
        isLoading = false
    }
    
    func readDescription(pokemon: Pokemon) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            return
        }
        
        let text = "\(pokemon.koreanName), \(pokemon.genus). \(pokemon.description)"
        let utterance = AVSpeechUtterance(string: text)
        
        let voices = AVSpeechSynthesisVoice.speechVoices()
        utterance.voice = voices.first { $0.name == "Yuna (Premium)" }
            ?? voices.first { $0.name.contains("Yuna") }
            ?? AVSpeechSynthesisVoice(language: "ko-KR")
        
        utterance.rate = 0.55
        utterance.pitchMultiplier = 0.8
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
}

// 진화 트리 뷰
struct EvolutionTreeView: View {
    let node: EvolutionNode
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            EvolutionPokemonView(id: node.id)
            
            if !node.evolvesTo.isEmpty {
                Image(systemName: "arrow.right")
                    .foregroundStyle(.gray)
                    .padding(.top, 28)
                
                if node.evolvesTo.count == 1 {
                    EvolutionTreeView(node: node.evolvesTo[0])
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(node.evolvesTo.enumerated()), id: \.offset) { _, child in
                            EvolutionTreeView(node: child)
                        }
                    }
                }
            }
        }
    }
}

struct EvolutionPokemonView: View {
    let id: Int
    
    var body: some View {
        NavigationLink(destination: PokedexDetailView(pokemonId: id)) {
            VStack(spacing: 4) {
                KFImage(URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(id).png"))
                    .placeholder { ProgressView().frame(width: 70, height: 70) }
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                Text("No.\(id)")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
        }
        .buttonStyle(.plain)
    }
}

struct SectionHeader: View {
    let title: String
    var color: Color = Color.gray.opacity(0.2)
    
    var body: some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(color)
    }
}

#Preview {
    PokedexDetailView(pokemonId: 256)
}
