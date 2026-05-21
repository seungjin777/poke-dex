import Foundation
import SwiftData

@Model
class CachedPokemon {
    var id: Int
    var name: String
    var koreanName: String
    var pokemonDescription: String  // description은 SwiftData 예약어라 변경
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
    
    func toPokemon() -> Pokemon {
        Pokemon(
            id: id,
            name: name,
            koreanName: koreanName,
            description: pokemonDescription,
            imageUrl: imageUrl,
            types: types
        )
    }
}
