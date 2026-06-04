import SwiftUI
import SceneKit
import RealityKit
import ARKit

// SceneKit 기반 3D 뷰어 (회전/확대/이동 내장)
struct Pokemon3DView: UIViewRepresentable {
    
    let modelURL: URL
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView(frame: .zero)
        
        // 기본 제스처 활성화 (회전, 확대, 이동)
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true  // 자동 조명 (텍스처 깨짐 해결)
        scnView.backgroundColor = UIColor.systemBackground
        scnView.antialiasingMode = .multisampling4X
        
        // usdzs 로드
        if let scene = try? SCNScene(url: modelURL) {
            scnView.scene = scene
            
            // 카메라 설정
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
        config.environmentTexturing = .automatic  // 추가
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
                        // ModelEntity.load 대신 loadAsync 사용
                        let entity = try await ModelEntity(contentsOf: modelURL)
                        entity.scale = SIMD3<Float>(0.3, 0.3, 0.3)
                        
                        // 텍스처 강제 적용
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
    
    @State private var modelURL: URL?      // 3D용
    @State private var arModelURL: URL?    // AR용
    
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
                    if let arUrl = arModelURL {
                        PokemonARViewContainer(modelURL: arUrl)
                            .ignoresSafeArea()
                    } else {
                        // AR 모델 로딩 중
                        ProgressView("AR 모델 로딩 중...")
                    }
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
            Task {
                await loadModel()
            }
        }
    }
    
    // PokemonModelView에서 loadModel 수정
    func loadModel() async {
        guard modelURL == nil && !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            let gender = hasGenderDifferences ? selectedGender : .none
            // 3D용 모델 로드
            let url = try await ModelService.shared.getModelURL(for: pokemonId, gender: gender, type: .view3D)
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
