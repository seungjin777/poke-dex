import SwiftUI
import Kingfisher

struct HistoryScanDetailView: View {
    
    let history: ScanHistory
    @State private var isShowingPokedex = false
    
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
                
                // 판별 결과 카드
                VStack(spacing: 16) {
                    
                    // 추정 포켓몬
                    HStack {
                        KFImage(URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(history.pokemonNumber).png"))
                            .placeholder { ProgressView().frame(width: 80, height: 80) }
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("추정 포켓몬")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(history.pokemonName)
                                .font(.title2)
                                .bold()
                            Text("No.\(String(format: "%04d", history.pokemonNumber))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // 촬영 정보
                    VStack(spacing: 12) {
                        InfoRow(label: "촬영일", value: history.date.formatted(date: .long, time: .shortened))
                        Divider()
                        InfoRow(label: "판별 신뢰도", value: String(format: "%.1f%%", history.confidence * 100))
                    }
                    .padding()
                    .background(.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
        }
        .navigationTitle("촬영 상세")
        .navigationBarTitleDisplayMode(.inline)
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

// 라벨 + 값 표시 공통 컴포넌트
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
            pokemonNumber: 54,
            pokemonName: "고라파덕",
            confidence: 0.92,
            imageData: Data()
        ))
    }
}
