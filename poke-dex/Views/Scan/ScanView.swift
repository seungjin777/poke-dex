import SwiftUI
import SwiftData
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = uiView.bounds
        }
    }
}

struct ScanView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedImage: UIImage?
    @State private var isShowingPhotoLibrary = false
    @State private var isLoading = false
    @State private var predictionResult: PredictionResponse?
    @State private var isShowingResult = false
    @State private var isShowingFailure = false
    
    @State private var scanErrorMessage: String?
    @State private var isShowingScanError = false
    
    @State private var isCameraActive = false
    @State private var captureSession = AVCaptureSession()
    @State private var photoOutput = AVCapturePhotoOutput()
    @State private var cameraDelegate: CameraDelegate?
    @State private var currentZoom: CGFloat = 1.0
    @State private var lastZoom: CGFloat = 1.0
    @State private var isCameraLoading = false
    
    @State private var isScanning = false
    @State private var scanBarOffset: CGFloat = 0
    @State private var scanAreaSize: CGFloat = 0  // GeometryReader에서 측정한 실제 이미지 영역 크기
    
    @State private var isBlinking = false
    
    let rotomBlue = Color(red: 0.29, green: 0.56, blue: 0.85)
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.96, green: 0.53, blue: 0.29),
                             Color(red: 0.91, green: 0.40, blue: 0.10),
                             Color(red: 0.82, green: 0.31, blue: 0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    
                    GeometryReader { geo in
                        let size = geo.size.width
                        
                        ZStack {
                            if isCameraActive {
                                CameraPreviewView(session: captureSession)
                                    .frame(width: size, height: size)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .gesture(
                                        MagnificationGesture()
                                            .onChanged { value in setZoom(lastZoom * value) }
                                            .onEnded { _ in lastZoom = currentZoom }
                                    )
                            } else if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: size, height: size)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                if isScanning {
                                    GeometryReader { _ in
                                        Rectangle()
                                            .fill(LinearGradient(
                                                colors: [.blue.opacity(0), .blue.opacity(0.8), .cyan.opacity(0.9), .blue.opacity(0.8), .blue.opacity(0)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ))
                                            .frame(height: 6)
                                            .shadow(color: .cyan, radius: 8)
                                            .offset(y: scanBarOffset)
                                    }
                                    .frame(width: size, height: size)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.3))
                                    .frame(width: size, height: size)
                                    .overlay {
                                        VStack(spacing: 12) {
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 50))
                                                .foregroundStyle(.white.opacity(0.7))
                                            Text("사진을 선택하거나 촬영해주세요")
                                                .foregroundStyle(.white.opacity(0.7))
                                        }
                                    }
                            }
                            
                            Path { p in
                                p.move(to: CGPoint(x: 20, y: 36))
                                p.addLine(to: CGPoint(x: 20, y: 20))
                                p.addLine(to: CGPoint(x: 36, y: 20))
                            }.stroke(rotomBlue, lineWidth: 3)
                            Path { p in
                                p.move(to: CGPoint(x: size - 36, y: 20))
                                p.addLine(to: CGPoint(x: size - 20, y: 20))
                                p.addLine(to: CGPoint(x: size - 20, y: 36))
                            }.stroke(rotomBlue, lineWidth: 3)
                            Path { p in
                                p.move(to: CGPoint(x: 20, y: size - 36))
                                p.addLine(to: CGPoint(x: 20, y: size - 20))
                                p.addLine(to: CGPoint(x: 36, y: size - 20))
                            }.stroke(rotomBlue, lineWidth: 3)
                            Path { p in
                                p.move(to: CGPoint(x: size - 36, y: size - 20))
                                p.addLine(to: CGPoint(x: size - 20, y: size - 20))
                                p.addLine(to: CGPoint(x: size - 20, y: size - 36))
                            }.stroke(rotomBlue, lineWidth: 3)
                        }
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(rotomBlue, lineWidth: 2.5))
                        .onAppear { scanAreaSize = geo.size.width }
                        .onChange(of: geo.size) { _, newSize in scanAreaSize = newSize.width }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .padding(.horizontal)
                    .overlay(alignment: .top) {
                        HStack(spacing: 25) {
                            Image("rotom_eyeL")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .scaleEffect(y: isBlinking ? 0.05 : 1.0)
                                .animation(.easeInOut(duration: 0.08), value: isBlinking)
                            
                            Image("rotom_eyeR")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .scaleEffect(y: isBlinking ? 0.05 : 1.0)
                                .animation(.easeInOut(duration: 0.08), value: isBlinking)
                        }
                        .padding(.horizontal)
                        .offset(y: -50)
                    }
                    .overlay(alignment: .center) {
                        if selectedImage == nil && !isCameraActive {
                            Image("rotom_mouth")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 60)
                                .padding(.top, -140)
                        }
                    }
                    .onAppear {
                        scheduleNextBlink()
                    }
                    
                    HStack(spacing: 16) {
                        Button {
                            if isCameraActive {
                                capturePhoto()
                            } else {
                                selectedImage = nil
                                startCamera()
                            }
                        } label: {
                            Label(isCameraActive ? "포착하기!" : "포켓몬 스캔", systemImage: isCameraActive ? "bolt.fill" : "camera.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isCameraActive ? .red : .blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.6), radius: 5, y: 7)
                        }
                        .disabled(isCameraLoading)
                        
                        Button {
                            if isCameraActive {
                                stopCamera()
                            } else {
                                isShowingPhotoLibrary = true
                            }
                        } label: {
                            Label(isCameraActive ? "취소" : "My 앨범", systemImage: isCameraActive ? "xmark" : "photo.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isCameraActive ? .gray : .green)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.6), radius: 5, y: 7)
                        }
                    }
                    .padding(.horizontal)
                    
                    if !isCameraActive {
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
                                    .shadow(color: .black.opacity(0.6), radius: 5, y: 7)
                            }
                        }
                        .disabled(selectedImage == nil || isLoading)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.top, 100)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.clear, for: .navigationBar)
            .sheet(isPresented: $isShowingPhotoLibrary, onDismiss: {
                if let image = selectedImage {
                    selectedImage = cropToSquare(image)
                }
            }) {
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
            .alert("서버 연결 실패", isPresented: $isShowingScanError) {
                Button("다시 시도") {
                    Task { await predictPokemon() }
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text(scanErrorMessage ?? "서버에 연결할 수 없어요.\nAI 서버가 켜져 있는지 확인해주세요.")
            }
            .onDisappear {
                stopCamera()
            }
        }
    }
    
    func startCamera() {
        Task {
            guard await AVCaptureDevice.requestAccess(for: .video) else { return }
                    
            captureSession = AVCaptureSession()
            photoOutput = AVCapturePhotoOutput()
            
            await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .background).async {
                    if captureSession.isRunning {
                        captureSession.stopRunning()
                    }
                    continuation.resume()
                }
            }
            
            captureSession = AVCaptureSession()
            photoOutput = AVCapturePhotoOutput()
            
            let device: AVCaptureDevice
            if #available(iOS 15.4, *),
               let macroDevice = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
                device = macroDevice
            } else if let wideDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                device = wideDevice
            } else {
                return
            }
            
            guard let input = try? AVCaptureDeviceInput(device: device) else { return }
            
            try? device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isAutoFocusRangeRestrictionSupported {
                device.autoFocusRangeRestriction = .none
            }
            device.unlockForConfiguration()
            
            captureSession.beginConfiguration()
            if captureSession.canAddInput(input) { captureSession.addInput(input) }
            if captureSession.canAddOutput(photoOutput) { captureSession.addOutput(photoOutput) }
            captureSession.commitConfiguration()
            
            DispatchQueue.global(qos: .background).async {
                captureSession.startRunning()
            }
            
            await MainActor.run {
                isCameraActive = true
                currentZoom = 1.0
                lastZoom = 1.0
            }
        }
    }
    
    func stopCamera() {
        captureSession.stopRunning()
        isCameraActive = false
    }
    
    func setZoom(_ zoom: CGFloat) {
        guard let device = (captureSession.inputs.first as? AVCaptureDeviceInput)?.device else { return }
        let maxZoom = min(device.activeFormat.videoMaxZoomFactor, 5.0)
        let clampedZoom = max(1.0, min(zoom, maxZoom))
        try? device.lockForConfiguration()
        device.videoZoomFactor = clampedZoom
        device.unlockForConfiguration()
        currentZoom = clampedZoom
    }
    
    func capturePhoto() {
        let delegate = CameraDelegate { image in
            DispatchQueue.main.async {
                selectedImage = cropToSquare(image)
                stopCamera()
            }
        }
        cameraDelegate = delegate
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }
    
    func cropToSquare(_ image: UIImage) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        let size = min(normalized.size.width, normalized.size.height)
        let origin = CGPoint(
            x: (normalized.size.width - size) / 2,
            y: (normalized.size.height - size) / 2
        )
        let cropRect = CGRect(origin: origin, size: CGSize(width: size, height: size))
        guard let cgImage = normalized.cgImage?.cropping(to: cropRect) else { return image }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
    }
    
    func startScanAnimation() {
        isScanning = true
        scanBarOffset = 0
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: true)) {
            scanBarOffset = scanAreaSize - 6
        }
    }
    
    func stopScanAnimation() {
        isScanning = false
        scanBarOffset = 0
    }
    
    func scheduleNextBlink() {
        let interval = Double.random(in: 0.1...5.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            isBlinking = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isBlinking = false
                scheduleNextBlink()
            }
        }
    }
    
    func predictPokemon() async {
        guard let image = selectedImage else { return }
        isLoading = true
        startScanAnimation()
        
        do {
            // 서버 요청과 최소 대기(1.5초 = 스캔바 1회 왕복)를 병렬 실행
            // 둘 다 끝나야 다음으로 넘어감
            async let result = PokeDexAPIService.shared.predictPokemon(image: image)
            async let minimumDelay: Void = Task.sleep(nanoseconds: 3_000_000_000)
            
            let (prediction, _) = try await (result, minimumDelay)
            
            predictionResult = prediction
            stopScanAnimation()
            
            if prediction.result == "success" {
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    let species = try await PokeAPIService.shared.fetchPokemonSpecies(id: prediction.number)
                    let history = ScanHistory(
                        pokemonNumber: prediction.number,
                        pokemonName: species.name,
                        confidence: prediction.confidence,
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
            
            let urlError = error as? URLError
            if urlError?.code == .timedOut {
                scanErrorMessage = "서버 응답 시간이 초과됐어요.\nAI 서버가 켜져 있는지 확인해주세요."
            } else if urlError?.code == .cannotConnectToHost || urlError?.code == .networkConnectionLost {
                scanErrorMessage = "서버에 연결할 수 없어요.\nAI 서버가 켜져 있는지 확인해주세요."
            } else {
                scanErrorMessage = "알 수 없는 오류가 발생했어요.\n잠시 후 다시 시도해주세요."
            }
            isShowingScanError = true
        }
        isLoading = false
    }
}

class CameraDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    let onCapture: (UIImage) -> Void
    
    init(onCapture: @escaping (UIImage) -> Void) {
        self.onCapture = onCapture
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        onCapture(image)
    }
}

#Preview {
    ScanView()
}
