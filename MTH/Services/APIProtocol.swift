import Foundation

protocol APIProtocol {
    func fetchMixes() async throws -> [Mix]
    func saveMix(_ mix: Mix) async throws
    func updateMix(_ mix: Mix) async throws
    func deleteMix(_ mix: Mix) async throws
    func setServerURL(_ url: String)
} 