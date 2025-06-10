import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int, message: String? = nil)
    case networkError(Error)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL сервера. Пожалуйста, проверьте настройки сервера."
        case .invalidResponse:
            return "Неверный ответ от сервера. Попробуйте позже."
        case .serverError(let statusCode, let message):
            if let message = message {
                return "Ошибка сервера (\(statusCode)): \(message)"
            }
            return "Ошибка сервера (код \(statusCode)). Попробуйте позже."
        case .networkError(let error):
            return "Ошибка сети: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Ошибка при обработке данных: \(error.localizedDescription)"
        }
    }
}

protocol APIProtocol {
    func setServerURL(_ url: String)
    func fetchMixes() async throws -> [Mix]
    func saveMix(_ mix: Mix) async throws
    func updateMix(_ mix: Mix) async throws
    func deleteMix(_ mix: Mix) async throws
    func getProfiles() async throws -> [Profile]
    func createProfile(name: String) async throws -> Profile
    func updateProfile(_ profile: Profile) async throws -> Profile
    func deleteProfile(id: String) async throws
}

class APIService: APIProtocol {
    static let shared = APIService()
    private var baseURL: String {
        UserDefaults.standard.string(forKey: "serverURL") ?? ""
    }
    
    private init() {}
    
    func setServerURL(_ url: String) {
        UserDefaults.standard.set(url, forKey: "serverURL")
    }
    
    private func checkServerURL() throws {
        guard !baseURL.isEmpty else {
            throw APIError.invalidURL
        }
        
        // Проверяем, что URL начинается с http:// или https://
        guard baseURL.hasPrefix("http://") || baseURL.hasPrefix("https://") else {
            throw APIError.invalidURL
        }
    }
    
    private func waitBeforeRetry(attempt: Int) async {
        let delay = pow(2.0, Double(attempt))
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }
    
    func fetchMixes() async throws -> [Mix] {
        try checkServerURL()
        guard let url = URL(string: "\(baseURL)/mixes") else { throw APIError.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
        return try JSONDecoder().decode([Mix].self, from: data)
    }
    
    func saveMix(_ mix: Mix) async throws {
        try checkServerURL()
        guard let url = URL(string: "\(baseURL)/mixes") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(mix)
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard httpResponse.statusCode == 201 else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
    }
    
    func updateMix(_ mix: Mix) async throws {
        try checkServerURL()
        guard let url = URL(string: "\(baseURL)/mixes/\(mix.id)") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(mix)
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
    }
    
    func deleteMix(_ mix: Mix) async throws {
        try checkServerURL()
        guard let url = URL(string: "\(baseURL)/mixes/\(mix.id)") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
    }
    
    func getProfiles() async throws -> [Profile] {
        try checkServerURL()
        guard let url = URL(string: "\(baseURL)/profiles") else { throw APIError.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
        return try JSONDecoder().decode([Profile].self, from: data)
    }
    
    func createProfile(name: String) async throws -> Profile {
        try checkServerURL()
        print("APIService: Base URL for createProfile: \(baseURL)")
        guard let url = URL(string: "\(baseURL)/profiles") else { 
            print("APIService: Invalid URL for profiles.")
            throw APIError.invalidURL 
        }
        print("APIService: Full URL for createProfile: \(url.absoluteString)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["name": name]
        request.httpBody = try JSONEncoder().encode(body)
        
        if let jsonBody = String(data: request.httpBody ?? Data(), encoding: .utf8) {
            print("APIService: Request body for createProfile: \(jsonBody)")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("APIService: Invalid response for createProfile.")
                throw APIError.invalidResponse
            }
            
            print("APIService: createProfile response status code: \(httpResponse.statusCode)")
            if httpResponse.statusCode == 201 {
                return try JSONDecoder().decode(Profile.self, from: data)
            } else {
                let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
                print("APIService: Server error during createProfile: \(errorMessage?["message"] ?? "No message")")
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorMessage?["message"])
            }
        } catch let error as APIError {
            print("APIService: APIError during createProfile: \(error.localizedDescription)")
            throw error
        } catch {
            print("APIService: Unknown error during createProfile: \(error.localizedDescription)")
            throw APIError.networkError(error)
        }
    }
    
    func updateProfile(_ profile: Profile) async throws -> Profile {
        try checkServerURL()
        guard let url = URL(string: "\(baseURL)/profiles/\(profile.id)") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(profile)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
        return try JSONDecoder().decode(Profile.self, from: data)
    }
    
    func deleteProfile(id: String) async throws {
        try checkServerURL()
        guard let url = URL(string: "\(baseURL)/profiles/\(id)") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
    }
} 
