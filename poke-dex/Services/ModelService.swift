import Foundation

// 성별 타입
enum PokemonGender {
    case male
    case female
    case none
}

class ModelService {
    
    static let shared = ModelService()
    
    private let baseURL = "http://192.168.45.205:8000" 
    
    private func localURL(for pokemonId: Int, gender: PokemonGender = .none) -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName: String
        switch gender {
        case .male:
            fileName = "\(pokemonId)-M.usdz"
        case .female:
            fileName = "\(pokemonId)-F.usdz"
        case .none:
            fileName = "\(pokemonId).usdz"
        }
        return documents.appendingPathComponent("models/\(fileName)")
    }
    
    func getModelURL(for pokemonId: Int, gender: PokemonGender = .none) async throws -> URL {
        let local = localURL(for: pokemonId, gender: gender)
        
        if FileManager.default.fileExists(atPath: local.path) {
            return local
        }
        
        return try await downloadModel(pokemonId: pokemonId, gender: gender)
    }
    
    private func downloadModel(pokemonId: Int, gender: PokemonGender) async throws -> URL {
        let fileName: String
        switch gender {
        case .male:
            fileName = "\(pokemonId)-M"
        case .female:
            fileName = "\(pokemonId)-F"
        case .none:
            fileName = "\(pokemonId)"
        }
        
        let url = URL(string: "\(baseURL)/pokemon/model/\(fileName)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let local = localURL(for: pokemonId, gender: gender)
        let modelsDir = local.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        try data.write(to: local)
        
        return local
    }
    
    func hasLocalModel(for pokemonId: Int, gender: PokemonGender = .none) -> Bool {
        FileManager.default.fileExists(atPath: localURL(for: pokemonId, gender: gender).path)
    }
}
