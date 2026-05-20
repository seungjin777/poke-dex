//
//  Untitled.swift
//  poke-dex
//
//  Created by 승진 on 5/20/26.
//

import SwiftUI

struct ScanFailureView: View {
    
    var onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.gray)
            
            Text("판별 실패")
                .font(.largeTitle)
                .bold()
            
            Text("포켓몬을 인식하지 못했어요\n다시 촬영해주세요")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Button {
                onRetry()
            } label: {
                Text("다시 촬영하기")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.red)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    ScanFailureView(onRetry: {})
}
