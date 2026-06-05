//
//  PokeDexAPIService.swift
//  poke-dex
//
//  Created by 승진 on 5/20/26.
//

import Foundation
import UIKit

// FastAPI 서버 응답 구조
struct PredictionResponse: Codable {
    let number: Int
    let confidence: Double
    let result: String  // "success" or "fail"
}

class PokeDexAPIService {
    
    static let shared = PokeDexAPIService()
    
    // 로컬 서버 주소 (실기기 테스트할 때 맥 IP로 변경)
    // 집 주소 "http://192.168.45.205:8000"
    // 아이폰 주소 "http://192.0.0.2:8000"
    // 학교 주소 "http://10.30.4.215"
    // 캡스톤 주소 "http://192.168.0.65"
    private let baseURL = "http://192.168.0.65:8000"
    
    // 이미지 전송 후 판별 결과 받기
    func predictPokemon(image: UIImage) async throws -> PredictionResponse {
        let url = URL(string: "\(baseURL)/pokemon/predictions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // multipart/form-data 형식으로 이미지 전송
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // 이미지를 JPEG로 변환
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw URLError(.badServerResponse)
        }
        
        // multipart body 구성
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"pokemon.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(PredictionResponse.self, from: data)
    }
}
