import SwiftUI
import SwiftData
import AVFoundation

struct ScanView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedImage: UIImage?
    @State private var isShowingCamera = false
    @State private var isShowingPhotoLibrary = false
    @State private var isLoading = false
    @State private var predictionResult: PredictionResponse?
    @State private var isShowingResult = false
    @State private var isShowingFailure = false
    
    // 스캔바 애니메이션
    @State private var isScanning = false
    @State private var scanBarOffset: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                
                // 이미지 영역
                ZStack {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // 스캔바 오버레이
                        if isScanning {
                            GeometryReader { geo in
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                .blue.opacity(0),
                                                .blue.opacity(0.8),
                                                .cyan.opacity(0.9),
                                                .blue.opacity(0.8),
                                                .blue.opacity(0)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(height: 6)
                                    .shadow(color: .cyan, radius: 8)
                                    .offset(y: scanBarOffset)
                            }
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
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
                }
                .frame(maxHeight: 300)
                
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
                    Task { await predictPokemon() }
                } label: {
                    if isLoading {
                        HStack(spacing: 8) {
                            ProgressView().tint(.white)
                            Text("스캔 중...")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.gray)
                        .foregroundStyle(.white)
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
                    PokedexDetailView(pokemonId: result.number, autoReadDescription: true)
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
    
    func startScanAnimation() {
        isScanning = true
        scanBarOffset = 0
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: true)) {
            scanBarOffset = 290
        }
    }
    
    func stopScanAnimation() {
        isScanning = false
        scanBarOffset = 0
    }
    
    func predictPokemon() async {
        guard let image = selectedImage else { return }
        isLoading = true
        startScanAnimation()
        
        do {
            let result = try await PokeDexAPIService.shared.predictPokemon(image: image)
            predictionResult = result
            stopScanAnimation()
            
            if result.result == "success" {
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    let species = try await PokeAPIService.shared.fetchPokemonSpecies(id: result.number)
                    let history = ScanHistory(
                        pokemonNumber: result.number,
                        pokemonName: species.name,
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
            stopScanAnimation()
            print("판별 실패: \(error)")
        }
        isLoading = false
    }
}

#Preview {
    ScanView()
}
