import Foundation

enum PokemonGender {
    case male
    case female
    case none
}

enum ModelType {
    case view3D
    case ar
}

class ModelService {
    
    static let shared = ModelService()
    
    private let baseURL = AppConfig.serverBaseURL
    
    // 서버가 꺼져 있을 때 무한 대기를 막기 위해 짧은 타임아웃 설정
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10   // 요청 시작 후 10초 내 응답 없으면 실패
        config.timeoutIntervalForResource = 30  // 전체 다운로드 30초 제한
        return URLSession(configuration: config)
    }()
    
    func getModelURL(for pokemonId: Int, gender: PokemonGender = .none, type: ModelType) async throws -> URL {
        return try await downloadModel(pokemonId: pokemonId, gender: gender, type: type)
    }
    
    private func downloadModel(pokemonId: Int, gender: PokemonGender, type: ModelType) async throws -> URL {
        let fileName: String
        switch gender {
        case .male:   fileName = "\(pokemonId)-M"
        case .female: fileName = "\(pokemonId)-F"
        case .none:   fileName = "\(pokemonId)"
        }
        
        let endpoint = type == .ar ? "modelAR" : "model3D"
        let url = URL(string: "\(baseURL)/pokemon/\(endpoint)/\(fileName)")!
        
        do {
            // URLSession.shared 대신 타임아웃이 설정된 session 사용
            let (data, response) = try await session.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404 {
                if gender != .none {
                    print("성별 모델 없음, 기본 모델로 폴백: \(pokemonId)")
                    return try await downloadModel(pokemonId: pokemonId, gender: .none, type: type)
                } else {
                    throw URLError(.fileDoesNotExist)
                }
            }
            
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
