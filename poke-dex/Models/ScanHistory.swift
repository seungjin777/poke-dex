//
//  ScanHistory.swift
//  poke-dex
//
//  Created by 승진 on 5/20/26.
//

import Foundation
import SwiftData

// SwiftData로 로컬에 저장될 히스토리 데이터 모델
@Model
class ScanHistory {
    var id: UUID
    var pokemonNumber: Int      // 판별된 포켓몬 번호
    var pokemonName: String     // 한국어 이름
    var confidence: Double      // 신뢰도
    var imageData: Data         // 촬영한 이미지
    var date: Date              // 촬영 날짜
    
    init(pokemonNumber: Int, pokemonName: String, confidence: Double, imageData: Data, date: Date = .now) {
        self.id = UUID()
        self.pokemonNumber = pokemonNumber
        self.pokemonName = pokemonName
        self.confidence = confidence
        self.imageData = imageData
        self.date = date
    }
}
