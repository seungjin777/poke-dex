import SwiftUI
import Kingfisher

struct SplashView: View {
    
    enum AppState {
        case title
        case loading
        case main
    }
    
    @State private var appState: AppState = .title
    
    var body: some View {
        switch appState {
        case .title:
            TitleView {
                appState = .loading
            }
        case .loading:
            LoadingView {
                appState = .main
            }
        case .main:
            ContentView()
        }
    }
}

struct TitleView: View {
    
    var onTap: () -> Void
    
    @State private var opacity = 0.0
    @State private var tapTextOpacity = 1.0
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.red.opacity(0.9), Color.red.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            Circle()
                .fill(.white.opacity(0.05))
                .frame(width: 400, height: 400)
                .offset(x: -80, y: -200)
            
            Circle()
                .fill(.white.opacity(0.05))
                .frame(width: 300, height: 300)
                .offset(x: 120, y: 200)
            
            VStack(spacing: 0) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 140, height: 140)
                    
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.red.opacity(0.9))
                            .frame(height: 64)
                        Rectangle()
                            .fill(.black)
                            .frame(height: 8)
                        Rectangle()
                            .fill(.white)
                            .frame(height: 64)
                    }
                    .frame(width: 140)
                    .clipShape(Circle())
                    
                    Circle()
                        .fill(.white)
                        .frame(width: 36, height: 36)
                        .overlay {
                            Circle()
                                .stroke(.black, lineWidth: 5)
                        }
                }
                .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                .padding(.bottom, 32)
                
                Text("PokéDex")
                    .font(.system(size: 52, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                
                Text("스마트 포켓몬 도감")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.top, 4)
                
                Spacer()
                
                Text("TAP TO START")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.vertical, 16)
                    .padding(.horizontal, 48)
                    .background(.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .opacity(tapTextOpacity)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.0).repeatForever()) {
                            tapTextOpacity = 0.3
                        }
                    }
                
                Text("©PokéDex Project")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 16)
                    .padding(.bottom, 32)
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 1.0
            }
        }
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 0.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onTap()
            }
        }
    }
}

struct LoadingView: View {
    
    var onComplete: () -> Void
    
    @State private var rotation = 0.0
    @State private var progress = 0.0
    @State private var statusText = "데이터를 불러오는 중입니다..."
    
    let preloadUrls = generations.map { generation in
        "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(generation.range.lowerBound).png"
    }
    
    var body: some View {
        ZStack {
            Color.red.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 100, height: 100)
                    
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.red.opacity(0.9))
                            .frame(height: 46)
                        Rectangle()
                            .fill(.black)
                            .frame(height: 6)
                        Rectangle()
                            .fill(.white)
                            .frame(height: 46)
                    }
                    .frame(width: 100)
                    .clipShape(Circle())
                    
                    Circle()
                        .fill(.white)
                        .frame(width: 26, height: 26)
                        .overlay {
                            Circle()
                                .stroke(.black, lineWidth: 4)
                        }
                }
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
                
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(.white.opacity(0.3))
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(.white)
                                    .frame(width: geo.size.width * progress)
                            }
                        }
                        .frame(height: 8)
                        .padding(.horizontal, 48)
                        
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    
                    Text(statusText)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                }
                
                Spacer()
            }
        }
        .task {
            await preloadImages()
        }
    }
    
    func preloadImages() async {
        let total = preloadUrls.count
        
        for (index, urlString) in preloadUrls.enumerated() {
            guard let url = URL(string: urlString) else { continue }
            
            await withCheckedContinuation { continuation in
                KingfisherManager.shared.retrieveImage(with: url) { _ in
                    continuation.resume()
                }
            }
            
            withAnimation(.linear(duration: 0.2)) {
                progress = Double(index + 1) / Double(total)
            }
        }
        
        statusText = "완료!"
        try? await Task.sleep(nanoseconds: 500_000_000)
        onComplete()
    }
}

#Preview {
    SplashView()
}
