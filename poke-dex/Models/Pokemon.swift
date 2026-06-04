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

struct PokemonStat {
    let name: String
    let value: Int
}

struct PokemonAbility {
    let name: String
    let isHidden: Bool
}

// 진화 트리 노드 (재귀 구조)
// indirect: 자기 자신을 참조하는 재귀 구조체에 필요
indirect enum EvolutionNode {
    case pokemon(id: Int, name: String, evolvesTo: [EvolutionNode])
    
    var id: Int {
        if case .pokemon(let id, _, _) = self { return id }
        return 0
    }
    
    var name: String {
        if case .pokemon(_, let name, _) = self { return name }
        return ""
    }
    
    var evolvesTo: [EvolutionNode] {
        if case .pokemon(_, _, let evolvesTo) = self { return evolvesTo }
        return []
    }
}

struct Pokemon: Identifiable {
    let id: Int
    let name: String
    let koreanName: String
    let description: String
    let imageUrl: String
    let types: [String]
    let height: Int
    let weight: Int
    let stats: [PokemonStat]
    let abilities: [PokemonAbility]
    let evolutionChain: EvolutionNode?  // 트리 구조로 변경
    let hasGenderDifferences: Bool
}
