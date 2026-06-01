import Foundation
import SwiftData

@Model
class CachedPokemon {
    var id: Int
    var name: String
    var koreanName: String
    var pokemonDescription: String
    var imageUrl: String
    var types: [String]
    var cachedAt: Date
    
    init(id: Int, name: String, koreanName: String, pokemonDescription: String, imageUrl: String, types: [String]) {
        self.id = id
        self.name = name
        self.koreanName = koreanName
        self.pokemonDescription = pokemonDescription
        self.imageUrl = imageUrl
        self.types = types
        self.cachedAt = .now
    }
    
    // 목록용 Pokemon 변환 (스탯/특성/진화는 빈 값)
    func toPokemon() -> Pokemon {
        Pokemon(
            id: id,
            name: name,
            koreanName: koreanName,
            description: pokemonDescription,
            imageUrl: imageUrl,
            types: types,
            height: 0,
            weight: 0,
            stats: [],
            abilities: [],
            evolutionChain: []
        )
    }
}
