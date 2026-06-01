import SwiftUI
import RealityKit
import ARKit

struct Pokemon3DView: UIViewRepresentable {
    
    let modelURL: URL
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.environment.background = .color(.systemBackground)
        
        do {
            let entity = try ModelEntity.load(contentsOf: modelURL)
            entity.scale = SIMD3<Float>(0.3, 0.3, 0.3)
            
            let anchor = AnchorEntity(world: .zero)
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)
            arView.cameraMode = .nonAR
        } catch {
            print("3D 모델 로드 실패: \(error)")
        }
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

struct PokemonARViewContainer: UIViewRepresentable {
    
    let modelURL: URL
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        arView.addGestureRecognizer(tapGesture)
        context.coordinator.arView = arView
        context.coordinator.modelURL = modelURL
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var arView: ARView?
        var modelURL: URL?
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView, let modelURL = modelURL else { return }
            
            let location = gesture.location(in: arView)
            let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
            
            if let result = results.first {
                do {
                    let entity = try ModelEntity.load(contentsOf: modelURL)
                    entity.scale = SIMD3<Float>(0.3, 0.3, 0.3)
                    
                    let anchor = AnchorEntity(raycastResult: result)
                    anchor.addChild(entity)
                    arView.scene.addAnchor(anchor)
                } catch {
                    print("AR 모델 배치 실패: \(error)")
                }
            }
        }
    }
}

struct PokemonModelView: View {
    
    let pokemonId: Int
    let pokemonName: String
    let hasGenderDifferences: Bool
    
    @State private var modelURL: URL?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAR = false
    @State private var selectedGender: PokemonGender = .male
    
    var body: some View {
        ZStack {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("3D 모델 다운로드 중...")
                        .foregroundStyle(.secondary)
                }
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.orange)
                    Text(error)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else if let url = modelURL {
                if showAR {
                    PokemonARViewContainer(modelURL: url)
                        .ignoresSafeArea()
                } else {
                    Pokemon3DView(modelURL: url)
                }
            }
            
            if !isLoading {
                VStack {
                    // 성별 선택 (성별 차이 있는 포켓몬만)
                    if hasGenderDifferences {
                        HStack(spacing: 12) {
                            Button {
                                selectedGender = .male
                                Task { await loadModel() }
                            } label: {
                                Label("수컷", systemImage: "♂")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedGender == .male ? .blue : .gray.opacity(0.3))
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                            
                            Button {
                                selectedGender = .female
                                Task { await loadModel() }
                            } label: {
                                Label("암컷", systemImage: "♀")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedGender == .female ? .pink : .gray.opacity(0.3))
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.top)
                    }
                    
                    Spacer()
                    
                    // 3D/AR 전환 버튼
                    if modelURL != nil {
                        Button {
                            showAR.toggle()
                        } label: {
                            Label(showAR ? "3D 보기" : "AR 보기", systemImage: showAR ? "cube" : "arkit")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(.blue)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationTitle("\(pokemonName) 3D")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await loadModel()
            }
        }
    }
    
    func loadModel() async {
        // 이미 로딩 중이거나 완료됐으면 스킵
        guard modelURL == nil && !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        do {
            let gender = hasGenderDifferences ? selectedGender : .none
            let url = try await ModelService.shared.getModelURL(for: pokemonId, gender: gender)
            print("모델 URL: \(url)")
            print("파일 존재: \(FileManager.default.fileExists(atPath: url.path))")
            modelURL = url
        } catch {
            print("모델 로드 에러: \(error)")
            errorMessage = "3D 모델을 불러올 수 없어요\n서버 연결을 확인해주세요"
        }
        isLoading = false
    }
}

#Preview {
    PokemonModelView(pokemonId: 1, pokemonName: "이상해씨", hasGenderDifferences: false)
}
