import Foundation

struct Generation {
    let id: Int
    let name: String
    let range: ClosedRange<Int>
}

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

// 포켓몬 스탯
struct PokemonStat {
    let name: String
    let value: Int
}

// 포켓몬 특성
struct PokemonAbility {
    let name: String
    let isHidden: Bool
}

// 진화 단계
struct EvolutionStep {
    let id: Int
    let name: String   // 영어 이름 (이미지 URL 생성용)
}

struct Pokemon: Identifiable {
    let id: Int
    let name: String
    let koreanName: String
    let description: String
    let imageUrl: String
    let types: [String]
    let height: Int                      // 키 (단위: 0.1m, 예: 7 = 0.7m)
    let weight: Int                      // 몸무게 (단위: 0.1kg, 예: 69 = 6.9kg)
    let stats: [PokemonStat]             // 스탯 목록
    let abilities: [PokemonAbility]      // 특성 목록
    let evolutionChain: [EvolutionStep]  // 진화 체인
}
