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
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // 404면 성별 모델 없는 거니까 기본 모델로 폴백
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404 {
                if gender != .none {
                    print("성별 모델 없음, 기본 모델로 폴백: \(pokemonId)")
                    return try await downloadModel(pokemonId: pokemonId, gender: .none)
                } else {
                    throw URLError(.fileDoesNotExist)
                }
            }
            
            let local = localURL(for: pokemonId, gender: gender)
            let modelsDir = local.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)
            try data.write(to: local)
            
            return local
            
        } catch {
            // 네트워크 에러일 때도 성별 모델이면 기본 모델로 폴백 시도
            if gender != .none {
                print("성별 모델 로드 실패, 기본 모델로 폴백: \(pokemonId)")
                return try await downloadModel(pokemonId: pokemonId, gender: .none)
            }
            throw error
        }
    }
    
    func hasLocalModel(for pokemonId: Int, gender: PokemonGender = .none) -> Bool {
        FileManager.default.fileExists(atPath: localURL(for: pokemonId, gender: gender).path)
    }
}
