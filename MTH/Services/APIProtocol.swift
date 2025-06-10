import Foundation

protocol APIProtocol {
    // MARK: - Mix Methods
    func getMixes() async throws -> [Mix]
    func saveMix(_ mix: Mix) async throws
    func updateMix(_ mix: Mix) async throws
    func deleteMix(_ mix: Mix) async throws
    
    // MARK: - Profile Methods
    func getProfiles() async throws -> [Profile]
    func createProfile(name: String) async throws -> Profile
    func updateProfile(_ profile: Profile) async throws -> Profile
    func deleteProfile(id: String) async throws
    
    // MARK: - Configuration
    func setServerURL(_ url: String)
} 