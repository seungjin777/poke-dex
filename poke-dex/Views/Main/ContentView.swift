import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    // 각 탭의 id — 바뀌면 해당 뷰가 완전히 재생성됨
    @State private var tabIDs = [0: UUID(), 1: UUID(), 2: UUID()]
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PokedexView()
                .id(tabIDs[0])
                .tabItem { Label("포켓몬 도감", systemImage: "book.fill") }
                .tag(0)
            
            ScanView()
                .id(tabIDs[1])
                .tabItem { Label("로토무 스캔", systemImage: "camera.fill") }
                .tag(1)
            
            HistoryView()
                .id(tabIDs[2])
                .tabItem { Label("My 히스토리", systemImage: "clock.fill") }
                .tag(2)
        }
        .onChange(of: selectedTab) { oldTab, newTab in
            // 떠난 탭의 id를 새로 발급 → 해당 뷰 완전 초기화
            tabIDs[oldTab] = UUID()
        }
    }
}

#Preview {
    ContentView()
}
