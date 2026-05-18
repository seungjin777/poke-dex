//
//  Pokemon.swift
//  poke-dex
//
//  Created by 승진 on 5/17/26.
//

import Foundation

struct Pokemon: Identifiable {
    let id: Int
    let name: String        // 영어 이름 (API 기본값)
    let koreanName: String  // 한국어 이름
    let description: String // 포켓몬 설명
    let imageUrl: String
    let types: [String]
}
