import SwiftUI
import SwiftData

struct ScanView: View {
    
    // SwiftData 컨텍스트 (데이터 저장/삭제 담당)
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedImage: UIImage?
    @State private var isShowingCamera = false
    @State private var isShowingPhotoLibrary = false
    @State private var isLoading = false
    @State private var predictionResult: PredictionResponse?
    @State private var isShowingResult = false
    @State private var isShowingFailure = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(maxHeight: 300)
                        .overlay {
                            VStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.gray)
                                Text("사진을 선택하거나 촬영해주세요")
                                    .foregroundStyle(.gray)
                            }
                        }
                }
                
                HStack(spacing: 16) {
                    Button {
                        isShowingCamera = true
                    } label: {
                        Label("카메라", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button {
                        isShowingPhotoLibrary = true
                    } label: {
                        Label("앨범", systemImage: "photo.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                
                Button {
                    Task {
                        await predictPokemon()
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Text("판별하기")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedImage == nil ? .gray : .red)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .disabled(selectedImage == nil || isLoading)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("스캔")
            .sheet(isPresented: $isShowingCamera) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
            }
            .sheet(isPresented: $isShowingPhotoLibrary) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
            }
            .navigationDestination(isPresented: $isShowingResult) {
                if let result = predictionResult {
                    PokemonDetailView(pokemon: Pokemon(
                        id: result.number,
                        name: "",
                        koreanName: "",
                        description: "",
                        imageUrl: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(result.number).png",
                        types: []
                    ))
                }
            }
            .navigationDestination(isPresented: $isShowingFailure) {
                ScanFailureView(onRetry: {
                    isShowingFailure = false
                    selectedImage = nil
                })
            }
        }
    }
    
    func predictPokemon() async {
        guard let image = selectedImage else { return }
        isLoading = true
        do {
            let result = try await PokeDexAPIService.shared.predictPokemon(image: image)
            predictionResult = result
            
            if result.result == "success" {
                // 판별 성공 시 히스토리 저장
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    let history = ScanHistory(
                        pokemonNumber: result.number,
                        pokemonName: "",  // 나중에 PokeAPI에서 이름 가져올 거야
                        confidence: result.confidence,
                        imageData: imageData
                    )
                    modelContext.insert(history)
                }
                isShowingResult = true
            } else {
                isShowingFailure = true
            }
        } catch {
            print("판별 실패: \(error)")
        }
        isLoading = false
    }
}

#Preview {
    ScanView()
}
