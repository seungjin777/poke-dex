import Foundation
import SwiftData

// 기본 포켓몬 API 응답
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

// species API 응답
struct PokemonSpeciesResponse: Codable {
    let names: [PokemonName]
    let flavor_text_entries: [FlavorTextEntry]
    let evolution_chain: EvolutionChainUrl
    let has_gender_differences: Bool  // 추가
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

// 진화 체인 API 응답
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

// 특성 한글 이름 API 응답
struct AbilityResponse: Codable {
    let names: [AbilityName]
}

struct AbilityName: Codable {
    let name: String
    let language: Language
}

// 타입 한글 매핑
let typeTranslations: [String: String] = [
    "normal": "노말", "fire": "불꽃", "water": "물",
    "grass": "풀", "electric": "전기", "ice": "얼음",
    "fighting": "격투", "poison": "독", "ground": "땅",
    "flying": "비행", "psychic": "에스퍼", "bug": "벌레",
    "rock": "바위", "ghost": "고스트", "dragon": "드래곤",
    "dark": "악", "steel": "강철", "fairy": "페어리"
]

// 스탯 한글 매핑
let statTranslations: [String: String] = [
    "hp": "HP",
    "attack": "공격",
    "defense": "방어",
    "special-attack": "특수공격",
    "special-defense": "특수방어",
    "speed": "스피드"
]

class PokeAPIService {
    
    static let shared = PokeAPIService()
    
    // 포켓몬 전체 정보 조회
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
                PokemonStat(
                    name: statTranslations[$0.stat.name] ?? $0.stat.name,
                    value: $0.base_stat
                )
            },
            abilities: abilities,
            evolutionChain: evolutionChain,
            hasGenderDifferences: species.hasGenderDifferences  // 추가
        )
    }
    
    // 세대별 목록 조회
    func fetchPokemonList(range: ClosedRange<Int>) async throws -> [Pokemon] {
        var pokemons: [Pokemon] = []
        for id in range {
            let pokemon = try await fetchPokemon(id: id)
            pokemons.append(pokemon)
        }
        return pokemons
    }
    
    // species 조회 (한글 이름, 설명, 진화체인 URL)
    func fetchPokemonSpecies(id: Int) async throws -> (name: String, description: String, evolutionChainUrl: String, hasGenderDifferences: Bool) {
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
        
        return (koreanName, koreanDescription, response.evolution_chain.url, response.has_gender_differences)
    }
    
    // 진화 체인 조회
    func fetchEvolutionChain(url: String) async throws -> [EvolutionStep] {
        let (data, _) = try await URLSession.shared.data(from: URL(string: url)!)
        let response = try JSONDecoder().decode(EvolutionChainResponse.self, from: data)
        
        var steps: [EvolutionStep] = []
        
        // 재귀적으로 진화 체인 파싱
        func parseChain(_ link: ChainLink) {
            // species URL에서 포켓몬 번호 추출 (예: .../pokemon-species/1/ → 1)
            let id = Int(link.species.url.split(separator: "/").last ?? "0") ?? 0
            steps.append(EvolutionStep(id: id, name: link.species.name))
            // 다음 진화가 있으면 재귀 호출
            if let next = link.evolves_to.first {
                parseChain(next)
            }
        }
        
        parseChain(response.chain)
        return steps
    }
    
    // 특성 한글 이름 조회
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
    
    // 캐시 확인 후 없으면 API 호출 (목록용 - 기본 정보만)
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
    
    // 세대별 목록 캐시 적용 버전
    func fetchPokemonListWithCache(range: ClosedRange<Int>, context: ModelContext) async throws -> [Pokemon] {
        var pokemons: [Pokemon] = []
        for id in range {
            let pokemon = try await fetchPokemonWithCache(id: id, context: context)
            pokemons.append(pokemon)
        }
        return pokemons
    }
}
