import Foundation

protocol APIProtocol {
    func fetchMixes() async throws -> [Mix]
    func saveMix(_ mix: Mix) async throws
    func updateMix(_ mix: Mix) async throws
    func deleteMix(_ mix: Mix) async throws
    func setServerURL(_ url: String)
}

class APIService: APIProtocol {
    static let shared = APIService()
    
    private let session: URLSession
    private var baseURL: String
    
    private init() {
        // Создаем сессию с увеличенным таймаутом
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300 // Увеличено до 5 минут
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
        
        // Используем URL из UserDefaults или дефолтный
        if let savedURL = UserDefaults.standard.string(forKey: "serverURL") {
            self.baseURL = savedURL
        } else {
            #if DEBUG
            self.baseURL = "http://localhost:3000/api"
            #else
            self.baseURL = "https://aromiqhookah.onrender.com/api"
            #endif
        }
        print("APIService initialized with baseURL: \(baseURL)")
    }
    
    func setServerURL(_ url: String) {
        UserDefaults.standard.set(url, forKey: "serverURL")
        self.baseURL = url
        print("Server URL updated to: \(url)")
    }
    
    private func waitBeforeRetry(attempt: Int) async {
        // Увеличиваем время ожидания с каждой попыткой
        let waitTime = UInt64(attempt * 10) // 10, 20, 30 секунд
        try? await Task.sleep(nanoseconds: waitTime * 1_000_000_000)
    }
    
    private func checkServerAvailability() async throws {
        guard let url = URL(string: "\(baseURL)/health") else {
            throw APIError.invalidURL
        }
        
        do {
            let (_, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverWakingUp
            }
        } catch {
            throw APIError.serverWakingUp
        }
    }
    
    func fetchMixes() async throws -> [Mix] {
        var attempt = 1
        let maxAttempts = 5 // Увеличено количество попыток
        
        while attempt <= maxAttempts {
            print("Начало загрузки миксов. Попытка \(attempt) из \(maxAttempts)")
            
            // Сначала проверяем доступность сервера
            do {
                try await checkServerAvailability()
            } catch {
                print("Сервер не доступен, ожидание...")
                await waitBeforeRetry(attempt: attempt)
                attempt += 1
                continue
            }
            
            guard let url = URL(string: "\(baseURL)/mixes") else {
                print("❌ Invalid URL: \(baseURL)/mixes")
                throw APIError.invalidURL
            }
            
            print("Fetching mixes from: \(url.absoluteString)")
            
            do {
                let (data, response) = try await session.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid response type")
                    throw APIError.invalidResponse
                }
                
                print("Response status code: \(httpResponse.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response body: \(responseString)")
                }
                
                guard httpResponse.statusCode == 200 else {
                    print("❌ Server returned status code: \(httpResponse.statusCode)")
                    throw APIError.serverError(statusCode: httpResponse.statusCode)
                }
                
                let decoder = JSONDecoder()
                let mixes = try decoder.decode([Mix].self, from: data)
                print("✅ Successfully decoded \(mixes.count) mixes")
                return mixes
            } catch let error as URLError {
                print("❌ Network error: \(error.localizedDescription)")
                if error.code == .timedOut {
                    if attempt < maxAttempts {
                        print("Сервер просыпается. Попытка \(attempt) из \(maxAttempts)")
                        await waitBeforeRetry(attempt: attempt)
                        attempt += 1
                        continue
                    }
                    throw APIError.serverWakingUp
                }
                throw APIError.networkError(error)
            } catch let error as DecodingError {
                print("❌ Decoding error: \(error)")
                throw APIError.decodingError(error)
            } catch {
                print("❌ Unexpected error: \(error)")
                throw error
            }
        }
        
        throw APIError.serverWakingUp
    }
    
    func saveMix(_ mix: Mix) async throws {
        print("Saving mix to: \(baseURL)/mixes")
        guard let url = URL(string: "\(baseURL)/mixes") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(mix)
        
        print("Request URL: \(url.absoluteString)")
        print("Request headers: \(request.allHTTPHeaderFields ?? [:])")
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Invalid response: \(response)")
                throw APIError.invalidResponse
            }
        } catch let error as URLError {
            if error.code == .timedOut {
                print("Request timed out. Server might be waking up...")
                throw APIError.serverWakingUp
            }
            throw APIError.networkError(error)
        }
    }
    
    func updateMix(_ mix: Mix) async throws {
        print("Updating mix at: \(baseURL)/mixes/\(mix.id)")
        guard let url = URL(string: "\(baseURL)/mixes/\(mix.id)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(mix)
        
        print("Request URL: \(url.absoluteString)")
        print("Request headers: \(request.allHTTPHeaderFields ?? [:])")
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Invalid response: \(response)")
                throw APIError.invalidResponse
            }
        } catch let error as URLError {
            if error.code == .timedOut {
                print("Request timed out. Server might be waking up...")
                throw APIError.serverWakingUp
            }
            throw APIError.networkError(error)
        }
    }
    
    func deleteMix(_ mix: Mix) async throws {
        print("Deleting mix at: \(baseURL)/mixes/\(mix.id)")
        guard let url = URL(string: "\(baseURL)/mixes/\(mix.id)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        print("Request URL: \(url.absoluteString)")
        print("Request headers: \(request.allHTTPHeaderFields ?? [:])")
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Invalid response: \(response)")
                throw APIError.invalidResponse
            }
        } catch let error as URLError {
            if error.code == .timedOut {
                print("Request timed out. Server might be waking up...")
                throw APIError.serverWakingUp
            }
            throw APIError.networkError(error)
        }
    }
}

// MARK: - Errors

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError(DecodingError)
    case networkError(URLError)
    case serverWakingUp
    case serverError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL сервера"
        case .invalidResponse:
            return "Неверный ответ от сервера"
        case .decodingError(let error):
            return "Ошибка при обработке данных: \(error)"
        case .networkError(let error):
            return "Ошибка сети: \(error.localizedDescription)"
        case .serverWakingUp:
            return "Сервер просыпается, попробуйте еще раз через несколько секунд"
        case .serverError(let statusCode):
            return "Ошибка сервера, статус код: \(statusCode)"
        }
    }
} 