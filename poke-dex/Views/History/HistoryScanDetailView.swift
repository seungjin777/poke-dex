import SwiftUI
import Kingfisher
import SwiftData

struct HistoryScanDetailView: View {
    
    let history: ScanHistory
    @State private var pokemon: Pokemon?
    
    // 삭제 후 이전 화면으로 돌아가기 위해 필요
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // 삭제 확인 알림 표시 여부
    @State private var showDeleteConfirm = false
    
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
                
                if let uiImage = UIImage(data: history.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                }
                
                VStack(spacing: 0) {
                    
                    ZStack(alignment: .bottom) {
                        typeBackground(types: pokemon?.types ?? [])
                            .frame(maxWidth: .infinity)
                            .frame(height: 140)
                        
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
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Text("No.\(String(format: "%04d", history.pokemonNumber))")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                                
                            Spacer()
                            
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
            if let _ = try? await PokeAPIService.shared.fetchPokemonSpecies(id: history.pokemonNumber) {
                pokemon = try? await PokeAPIService.shared.fetchPokemon(id: history.pokemonNumber)
            }
        }
        // 삭제 확인 Alert
        .alert("촬영 기록 삭제", isPresented: $showDeleteConfirm) {
            Button("삭제", role: .destructive) {
                modelContext.delete(history)
                dismiss()  // 삭제 후 목록으로 자동 이동
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("이 촬영 기록을 삭제하면 복구할 수 없어요.")
        }
        // 하단 버튼 두 개: 삭제 (좌) + 도감 보기 (우)
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: 12) {
                // 삭제 버튼
                Button {
                    showDeleteConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("삭제")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.gray.opacity(0.85))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(radius: 4)
                }
                
                // 도감 보기 버튼
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
