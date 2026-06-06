import SwiftUI
import Kingfisher

struct HistoryScanDetailView: View {
    
    let history: ScanHistory
    @State private var pokemon: Pokemon?
    
    // 타입 컬러 그라데이션 (PokedexDetailView와 동일)
    @ViewBuilder
    func typeBackground(types: [String]) -> some View {
        let colors = types.compactMap { typeColors[$0] }
        if colors.count >= 2 {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if let color = colors.first {
            LinearGradient(colors: [color, color.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // 촬영한 이미지
                if let uiImage = UIImage(data: history.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                }
                
                // 판별 결과 + 촬영 정보 통합 카드
                VStack(spacing: 0) {
                    
                    // 타입 그라데이션 상단 영역
                    ZStack(alignment: .bottom) {
                        typeBackground(types: pokemon?.types ?? [])
                            .frame(maxWidth: .infinity)
                            .frame(height: 140)
                        
                        // 포켓몬 이미지 + 이름
                        HStack(spacing: 16) {
                            KFImage(URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(history.pokemonNumber).png"))
                                    .placeholder { ProgressView().frame(width: 80, height: 80) }
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 90, height: 90)
                                    .shadow(color: .black.opacity(0.4), radius: 4, y: 4)
                                
                            VStack(alignment: .leading, spacing: 4) {
                                Text("추정 포켓몬")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                                Text(history.pokemonName)
                                    .font(.title3)  // title2 → title3
                                    .bold()
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)  // 공간 부족하면 자동으로 축소
                                Text("No.\(String(format: "%04d", history.pokemonNumber))")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                                
                            Spacer()
                            
                            // 타입 아이콘만
                            if let types = pokemon?.types {
                                HStack(spacing: 6) {
                                    ForEach(types, id: \.self) { type in
                                        let englishName = typeTranslations.first { $0.value == type }?.key ?? type
                                        Image(englishName)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 36, height: 36)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                            
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                    
                    // 촬영 정보 (흰색 배경)
                    VStack(spacing: 12) {
                        InfoRow(label: "촬영일", value: history.date.formatted(date: .long, time: .shortened))
                        Divider()
                        InfoRow(label: "판별 신뢰도", value: String(format: "%.1f%%", history.confidence * 100))
                    }
                    .padding()
                    .background(.white)
                }
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 20,
                    bottomLeadingRadius: 12,
                    bottomTrailingRadius: 12,
                    topTrailingRadius: 20
                ))
                
                Spacer()
            }
            .padding(.top)
        }
        .navigationTitle("촬영 상세")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // 타입 정보 로드
            if let cached = try? await PokeAPIService.shared.fetchPokemonSpecies(id: history.pokemonNumber) {
                pokemon = try? await PokeAPIService.shared.fetchPokemon(id: history.pokemonNumber)
            }
        }
        // 우측 하단 도감 보기 버튼
        .overlay(alignment: .bottomTrailing) {
            NavigationLink(destination: PokedexDetailView(pokemonId: history.pokemonNumber)) {
                HStack {
                    Image(systemName: "book.fill")
                    Text("도감 보기")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.red)
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .shadow(radius: 4)
            }
            .padding()
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
}

#Preview {
    NavigationStack {
        HistoryScanDetailView(history: ScanHistory(
            pokemonNumber: 643,
            pokemonName: "일레도리자드",
            confidence: 0.84,
            imageData: Data()
        ))
    }
}
