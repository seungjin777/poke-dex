import Foundation
import UIKit

struct PredictionResponse: Codable {
    let number: Int
    let confidence: Double
    let result: String  // "success" or "fail"
}

class PokeDexAPIService {
    
    static let shared = PokeDexAPIService()
    private let baseURL = AppConfig.serverBaseURL
    
    // 서버가 꺼져 있을 때 무한 대기를 막기 위해 짧은 타임아웃 설정
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10   // 10초 내 응답 없으면 실패
        config.timeoutIntervalForResource = 30  // 전체 업로드/다운로드 30초 제한
        return URLSession(configuration: config)
    }()
    
    func predictPokemon(image: UIImage) async throws -> PredictionResponse {
        let url = URL(string: "\(baseURL)/pokemon/predictions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw URLError(.badServerResponse)
        }
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"pokemon.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // URLSession.shared 대신 타임아웃이 설정된 session 사용
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(PredictionResponse.self, from: data)
    }
}
