import Foundation
import SwiftData
import SwiftUI

struct PokemonResponse: Codable {
    let id: Int
    let name: String
    let sprites: Sprites
    let types: [TypeSlot]
    let height: Int
    let weight: Int
    let stats: [StatSlot]
    let abilities: [AbilitySlot]
}

struct Sprites: Codable {
    let other: OtherSprites
}

struct OtherSprites: Codable {
    let official_artwork: OfficialArtwork
    enum CodingKeys: String, CodingKey {
        case official_artwork = "official-artwork"
    }
}

struct OfficialArtwork: Codable {
    let front_default: String
}

struct TypeSlot: Codable {
    let type: TypeInfo
}

struct TypeInfo: Codable {
    let name: String
}

struct StatSlot: Codable {
    let base_stat: Int
    let stat: StatInfo
}

struct StatInfo: Codable {
    let name: String
}

struct AbilitySlot: Codable {
    let ability: AbilityInfo
    let is_hidden: Bool
}

struct AbilityInfo: Codable {
    let name: String
}

struct PokemonSpeciesResponse: Codable {
    let names: [PokemonName]
    let flavor_text_entries: [FlavorTextEntry]
    let evolution_chain: EvolutionChainUrl
    let has_gender_differences: Bool
    let gender_rate: Int
    let genera: [Genus]
}

struct EvolutionChainUrl: Codable {
    let url: String
}

struct PokemonName: Codable {
    let name: String
    let language: Language
}

struct FlavorTextEntry: Codable {
    let flavor_text: String
    let language: Language
}

struct Language: Codable {
    let name: String
}

struct EvolutionChainResponse: Codable {
    let chain: ChainLink
}

struct ChainLink: Codable {
    let species: SpeciesInfo
    let evolves_to: [ChainLink]
}

struct SpeciesInfo: Codable {
    let name: String
    let url: String
}

struct AbilityResponse: Codable {
    let names: [AbilityName]
}

struct AbilityName: Codable {
    let name: String
    let language: Language
}

struct Genus: Codable {
    let genus: String
    let language: Language
}

let typeTranslations: [String: String] = [
    "normal": "노말", "fire": "불꽃", "water": "물",
    "grass": "풀", "electric": "전기", "ice": "얼음",
    "fighting": "격투", "poison": "독", "ground": "땅",
    "flying": "비행", "psychic": "에스퍼", "bug": "벌레",
    "rock": "바위", "ghost": "고스트", "dragon": "드래곤",
    "dark": "악", "steel": "강철", "fairy": "페어리"
]

let statTranslations: [String: String] = [
    "hp": "HP", "attack": "공격", "defense": "방어",
    "special-attack": "특수공격", "special-defense": "특수방어", "speed": "스피드"
]

// 포켓몬 타입별 고유 색상 (한국어 타입명 기준)
let typeColors: [String: Color] = [
    "노말":   Color(red: 0.62, green: 0.62, blue: 0.62),
    "불꽃":   Color(red: 0.94, green: 0.40, blue: 0.13),
    "물":     Color(red: 0.24, green: 0.56, blue: 0.94),
    "풀":     Color(red: 0.30, green: 0.69, blue: 0.26),
    "전기":   Color(red: 0.98, green: 0.78, blue: 0.09),
    "얼음":   Color(red: 0.40, green: 0.80, blue: 0.87),
    "격투":   Color(red: 0.76, green: 0.19, blue: 0.10),
    "독":     Color(red: 0.63, green: 0.25, blue: 0.63),
    "땅":     Color(red: 0.80, green: 0.62, blue: 0.22),
    "비행":   Color(red: 0.42, green: 0.56, blue: 0.90),
    "에스퍼": Color(red: 0.97, green: 0.22, blue: 0.46),
    "벌레":   Color(red: 0.65, green: 0.72, blue: 0.08),
    "바위":   Color(red: 0.71, green: 0.63, blue: 0.22),
    "고스트": Color(red: 0.44, green: 0.34, blue: 0.59),
    "드래곤": Color(red: 0.44, green: 0.22, blue: 0.94),
    "악":     Color(red: 0.44, green: 0.31, blue: 0.22),
    "강철":   Color(red: 0.72, green: 0.72, blue: 0.82),
    "페어리": Color(red: 0.94, green: 0.51, blue: 0.71)
]

class PokeAPIService {
    
    static let shared = PokeAPIService()
    
    func fetchPokemon(id: Int) async throws -> Pokemon {
        let url = URL(string: "https://pokeapi.co/api/v2/pokemon/\(id)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(PokemonResponse.self, from: data)
        
        let species = try await fetchPokemonSpecies(id: id)
        let evolutionChain = try await fetchEvolutionChain(url: species.evolutionChainUrl)
        let abilities = try await fetchAbilities(slots: response.abilities)
        
        return Pokemon(
            id: response.id,
            name: response.name,
            koreanName: species.name,
            description: species.description,
            imageUrl: response.sprites.other.official_artwork.front_default,
            types: response.types.map { typeTranslations[$0.type.name] ?? $0.type.name },
            height: response.height,
            weight: response.weight,
            stats: response.stats.map {
                PokemonStat(name: statTranslations[$0.stat.name] ?? $0.stat.name, value: $0.base_stat)
            },
            abilities: abilities,
            evolutionChain: evolutionChain,
            hasGenderDifferences: species.hasGenderDifferences,
            genderRate: species.genderRate,
            genus: species.genus
        )
    }
    
    func fetchPokemonList(range: ClosedRange<Int>) async throws -> [Pokemon] {
        var pokemons: [Pokemon] = []
        for id in range {
            let pokemon = try await fetchPokemon(id: id)
            pokemons.append(pokemon)
        }
        return pokemons
    }
    
    func fetchPokemonSpecies(id: Int) async throws -> (name: String, description: String, evolutionChainUrl: String, hasGenderDifferences: Bool, genderRate: Int, genus: String) {
        let url = URL(string: "https://pokeapi.co/api/v2/pokemon-species/\(id)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(PokemonSpeciesResponse.self, from: data)
        
        let koreanName = response.names.first { $0.language.name == "ko" }?.name ?? "알 수 없음"
        let koreanDescription = response.flavor_text_entries
            .first { $0.language.name == "ko" }?
            .flavor_text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            ?? response.flavor_text_entries
            .first { $0.language.name == "en" }?
            .flavor_text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            ?? "설명 없음"
        let koreanGenus = response.genera.first { $0.language.name == "ko" }?.genus ?? ""
        
        return (koreanName, koreanDescription, response.evolution_chain.url, response.has_gender_differences, response.gender_rate, koreanGenus)
    }
    
    // 진화 체인 조회 - 트리 구조로 파싱
    func fetchEvolutionChain(url: String) async throws -> EvolutionNode? {
        let (data, _) = try await URLSession.shared.data(from: URL(string: url)!)
        let response = try JSONDecoder().decode(EvolutionChainResponse.self, from: data)
        
        func parseNode(_ link: ChainLink) -> EvolutionNode {
            let id = Int(link.species.url.split(separator: "/").last ?? "0") ?? 0
            let children = link.evolves_to.map { parseNode($0) }
            return .pokemon(id: id, name: link.species.name, evolvesTo: children)
        }
        
        return parseNode(response.chain)
    }
    
    func fetchAbilities(slots: [AbilitySlot]) async throws -> [PokemonAbility] {
        var abilities: [PokemonAbility] = []
        for slot in slots {
            let url = URL(string: "https://pokeapi.co/api/v2/ability/\(slot.ability.name)")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(AbilityResponse.self, from: data)
            let koreanName = response.names.first { $0.language.name == "ko" }?.name ?? slot.ability.name
            abilities.append(PokemonAbility(name: koreanName, isHidden: slot.is_hidden))
        }
        return abilities
    }
    
    func fetchPokemonWithCache(id: Int, context: ModelContext) async throws -> Pokemon {
        let descriptor = FetchDescriptor<CachedPokemon>(
            predicate: #Predicate { $0.id == id }
        )
        
        if let cached = try? context.fetch(descriptor).first {
            return cached.toPokemon()
        }
        
        let pokemon = try await fetchPokemon(id: id)
        
        let cached = CachedPokemon(
            id: pokemon.id,
            name: pokemon.name,
            koreanName: pokemon.koreanName,
            pokemonDescription: pokemon.description,
            imageUrl: pokemon.imageUrl,
            types: pokemon.types
        )
        context.insert(cached)
        
        return pokemon
    }
    
    func fetchPokemonListWithCache(range: ClosedRange<Int>, context: ModelContext) async throws -> [Pokemon] {
        var pokemons: [Pokemon] = []
        for id in range {
            let pokemon = try await fetchPokemonWithCache(id: id, context: context)
            pokemons.append(pokemon)
        }
        return pokemons
    }
}
