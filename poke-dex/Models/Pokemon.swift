//
//  Pokemon.swift
//  poke-dex
//
//  Created by 승진 on 5/17/26.
//

import Foundation

// 세대 정보를 담는 구조체
struct Generation {
    let id: Int           // 세대 번호
    let name: String      // 세대 이름 (예: 관동)
    let range: ClosedRange<Int> // 포켓몬 번호 범위
}

// 전체 세대 목록 (전역 상수)
let generations: [Generation] = [
    Generation(id: 1, name: "관동", range: 1...151),
    Generation(id: 2, name: "성도", range: 152...251),
    Generation(id: 3, name: "호연", range: 252...386),
    Generation(id: 4, name: "신오", range: 387...493),
    Generation(id: 5, name: "하나", range: 494...649),
    Generation(id: 6, name: "칼로스", range: 650...721),
    Generation(id: 7, name: "알로라", range: 722...809),
    Generation(id: 8, name: "가라르", range: 810...905),
    Generation(id: 9, name: "팔데아", range: 906...1025)
]

struct Pokemon: Identifiable {
    let id: Int
    let name: String        // 영어 이름
    let koreanName: String  // 한국어 이름
    let description: String // 포켓몬 설명
    let imageUrl: String    // 이미지 URL
    let types: [String]     // 타입 목록
}
