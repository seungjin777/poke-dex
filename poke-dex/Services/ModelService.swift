import Foundation

enum PokemonGender {
    case male
    case female
    case none
}

// 3D 뷰어용인지 AR용인지 구분
enum ModelType {
    case view3D
    case ar
}

class ModelService {
    
    static let shared = ModelService()
    
    private let baseURL = AppConfig.serverBaseURL
    
    func getModelURL(for pokemonId: Int, gender: PokemonGender = .none, type: ModelType) async throws -> URL {
        return try await downloadModel(pokemonId: pokemonId, gender: gender, type: type)
    }
    
    private func downloadModel(pokemonId: Int, gender: PokemonGender, type: ModelType) async throws -> URL {
        let fileName: String
        switch gender {
        case .male: fileName = "\(pokemonId)-M"
        case .female: fileName = "\(pokemonId)-F"
        case .none: fileName = "\(pokemonId)"
        }
        
        // 3D/AR 엔드포인트 분리
        let endpoint = type == .ar ? "modelAR" : "model3D"
        let url = URL(string: "\(baseURL)/pokemon/\(endpoint)/\(fileName)")!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404 {
                if gender != .none {
                    print("성별 모델 없음, 기본 모델로 폴백: \(pokemonId)")
                    return try await downloadModel(pokemonId: pokemonId, gender: .none, type: type)
                } else {
                    throw URLError(.fileDoesNotExist)
                }
            }
            
            // 임시 디렉토리에 저장
            let temp = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(type == .ar ? "ar" : "3d")_\(fileName).usdz")
            try data.write(to: temp)
            
            return temp
            
        } catch {
            if gender != .none {
                return try await downloadModel(pokemonId: pokemonId, gender: .none, type: type)
            }
            throw error
        }
    }
}
