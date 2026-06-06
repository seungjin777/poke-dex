import SwiftUI

struct TypeBadgeView: View {
    let typeName: String
    
    var englishName: String {
        typeTranslations.first { $0.value == typeName }?.key ?? typeName
    }
    
    var body: some View {
        HStack(spacing: 6) {
            // 둥근 사각형 = 이미지 크기와 동일
            Image(englishName)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(typeName)
                .font(.subheadline)
                .bold()
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        TypeBadgeView(typeName: "노말")
        TypeBadgeView(typeName: "비행")
        TypeBadgeView(typeName: "불꽃")
    }
    .padding()
}
