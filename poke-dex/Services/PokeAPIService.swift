//
//  PokeAPIService.swift
//  poke-dex
//
//  Created by 승진 on 5/17/26.
//

import Foundation

// PokeAPI 응답 데이터 구조 (JSON 파싱용)
struct PokemonResponse: Codable {
    let id: Int
    let name: String
    let sprites: Sprites
    let types: [TypeSlot]
}

struct Sprites: Codable {
    let front_default: String
}

struct TypeSlot: Codable {
    let type: TypeInfo
}

struct TypeInfo: Codable {
    let name: String
}

// pokemon-species API 응답 구조
struct PokemonSpeciesResponse: Codable {
    let names: [PokemonName]
    let flavor_text_entries: [FlavorTextEntry]
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

// PokeAPI 호출 담당 클래스
class PokeAPIService {
    
    static let shared = PokeAPIService() // 앱 전체에서 하나의 인스턴스만 사용
    
    func fetchPokemon(id: Int) async throws -> Pokemon {
        let url = URL(string: "https://pokeapi.co/api/v2/pokemon/\(id)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(PokemonResponse.self, from: data)
        
        // species API 추가 호출
        let species = try await fetchPokemonSpecies(id: id)
        
        return Pokemon(
            id: response.id,
            name: response.name,
            koreanName: species.name,
            description: species.description,
            imageUrl: response.sprites.front_default,
            types: response.types.map { $0.type.name }
        )
    }
    
    // 포켓몬 목록 가져오기 (1번 ~ 151번)
    func fetchPokemonList() async throws -> [Pokemon] {
        var pokemons: [Pokemon] = []
        for id in 1...151 {
            let pokemon = try await fetchPokemon(id: id)
            pokemons.append(pokemon)
        }
        return pokemons
    }
    
    // 한국어 이름이랑 설명 가져오기
    func fetchPokemonSpecies(id: Int) async throws -> (name: String, description: String) {
        let url = URL(string: "https://pokeapi.co/api/v2/pokemon-species/\(id)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(PokemonSpeciesResponse.self, from: data)
        
        // 한국어 이름 찾기
        let koreanName = response.names.first { $0.language.name == "ko" }?.name ?? "알 수 없음"
        
        // 한국어 설명 찾기 (줄바꿈 문자 제거)
        let koreanDescription = response.flavor_text_entries
            .first { $0.language.name == "ko" }?
            .flavor_text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ") ?? "설명 없음"
        
        return (koreanName, koreanDescription)
    }
}
