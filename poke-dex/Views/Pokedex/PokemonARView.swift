import SwiftUI
import SceneKit
import RealityKit
import ARKit

struct Pokemon3DView: UIViewRepresentable {
    
    let modelURL: URL
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView(frame: .zero)
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.backgroundColor = UIColor.systemBackground
        scnView.antialiasingMode = .multisampling4X
        
        if let scene = try? SCNScene(url: modelURL) {
            scnView.scene = scene
            let cameraNode = SCNNode()
            cameraNode.camera = SCNCamera()
            cameraNode.position = SCNVector3(0, 0, 3)
            scene.rootNode.addChildNode(cameraNode)
        }
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
}

struct PokemonARViewContainer: UIViewRepresentable {
    
    let modelURL: URL
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
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
                Task {
                    do {
                        let entity = try await ModelEntity(contentsOf: modelURL)
                        entity.scale = SIMD3<Float>(0.3, 0.3, 0.3)
                        entity.model?.materials = entity.model?.materials ?? []
                        
                        let anchor = AnchorEntity(raycastResult: result)
                        anchor.addChild(entity)
                        
                        await MainActor.run {
                            arView.scene.addAnchor(anchor)
                        }
                    } catch {
                        print("AR 모델 배치 실패: \(error)")
                    }
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
    @State private var arModelURL: URL?
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAR = false
    @State private var selectedGender: PokemonGender = .male
    
    func loadARModel() async {
        do {
            let gender = hasGenderDifferences ? selectedGender : .none
            arModelURL = try await ModelService.shared.getModelURL(for: pokemonId, gender: gender, type: .ar)
        } catch {
            print("AR 모델 로드 에러: \(error)")
        }
    }
    
    var body: some View {
        ZStack {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("3D 모델 다운로드 중...")
                        .foregroundStyle(.secondary)
                }
            } else if let error = errorMessage {
                // 에러 상태: 메시지 + 재시도 버튼
                VStack(spacing: 20) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 50))
                        .foregroundStyle(.orange)
                    Text(error)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        // 재시도: 상태 초기화 후 다시 로드
                        errorMessage = nil
                        modelURL = nil
                        Task { await loadModel() }
                    } label: {
                        Label("다시 시도", systemImage: "arrow.clockwise")
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                .padding()
            } else if let url = modelURL {
                if showAR {
                    if let arUrl = arModelURL {
                        PokemonARViewContainer(modelURL: arUrl)
                            .ignoresSafeArea()
                    } else {
                        ProgressView("AR 모델 로딩 중...")
                    }
                } else {
                    Pokemon3DView(modelURL: url)
                }
            }
            
            if !isLoading && errorMessage == nil {
                VStack {
                    if hasGenderDifferences {
                        HStack(spacing: 12) {
                            // 수컷 버튼 — systemImage 제거하고 텍스트로
                            Button {
                                selectedGender = .male
                                modelURL = nil
                                arModelURL = nil
                                Task { await loadModel() }
                            } label: {
                                HStack(spacing: 6) {
                                    Text("♂").bold()
                                    Text("수컷")
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedGender == .male ? .blue : .gray.opacity(0.3))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                            }

                            // 암컷 버튼
                            Button {
                                selectedGender = .female
                                modelURL = nil
                                arModelURL = nil
                                Task { await loadModel() }
                            } label: {
                                HStack(spacing: 6) {
                                    Text("♀").bold()
                                    Text("암컷")
                                }
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
                    
                    Button {
                        showAR.toggle()
                        if showAR && arModelURL == nil {
                            Task { await loadARModel() }
                        }
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
        .navigationTitle("\(pokemonName) 3D")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { await loadModel() }
        }
    }
    
    func loadModel() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            let gender = hasGenderDifferences ? selectedGender : .none
            let url = try await ModelService.shared.getModelURL(for: pokemonId, gender: gender, type: .view3D)
            modelURL = url
            
            // AR 모드 상태에서 성별 바꿨을 때 AR 모델도 자동 로드
            if showAR {
                await loadARModel()
            }
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
