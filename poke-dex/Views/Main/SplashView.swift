import SwiftUI

struct SplashView: View {
    
    @State private var isActive = false
    @State private var opacity = 0.0
    @State private var scale = 0.8
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                // 배경색
                Color.red.opacity(0.85)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // 포켓볼 아이콘
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "circle.fill")
                            .font(.system(size: 120))
                            .foregroundStyle(.white.opacity(0.1))
                        
                        VStack(spacing: 0) {
                            // 포켓볼 상단 (빨간색)
                            Rectangle()
                                .fill(Color.red.opacity(0.85))
                                .frame(height: 55)
                            // 중간 띠
                            Rectangle()
                                .fill(.black)
                                .frame(height: 8)
                            // 포켓볼 하단 (흰색)
                            Rectangle()
                                .fill(.white)
                                .frame(height: 55)
                        }
                        .frame(width: 120)
                        .clipShape(Circle())
                        
                        // 중앙 버튼
                        Circle()
                            .fill(.white)
                            .frame(width: 30, height: 30)
                            .overlay {
                                Circle()
                                    .stroke(.black, lineWidth: 4)
                            }
                    }
                    
                    // 앱 이름
                    Text("PokéDex")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text("AI 포켓몬 도감")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    // 페이드인 + 스케일 애니메이션
                    withAnimation(.easeOut(duration: 0.6)) {
                        opacity = 1.0
                        scale = 1.0
                    }
                    // 2초 후 메인 화면으로 전환
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            isActive = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
