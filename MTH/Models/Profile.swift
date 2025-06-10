import Foundation

struct Profile: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var isActive: Bool
    
    init(id: String = UUID().uuidString, name: String, isActive: Bool = false) {
        self.id = id
        self.name = name
        self.isActive = isActive
    }
}

class ProfileManager {
    private static let userDefaults = UserDefaults.standard
    private static let profilesKey = "profiles"
    private static let activeProfileIdKey = "activeProfileId"
    
    static var profiles: [Profile] {
        get {
            guard let data = userDefaults.data(forKey: profilesKey),
                  let profiles = try? JSONDecoder().decode([Profile].self, from: data) else {
                return []
            }
            return profiles
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                userDefaults.set(data, forKey: profilesKey)
            }
        }
    }
    
    static var activeProfileId: String? {
        get {
            return userDefaults.string(forKey: activeProfileIdKey)
        }
        set {
            userDefaults.set(newValue, forKey: activeProfileIdKey)
        }
    }
    
    static var activeProfile: Profile? {
        get {
            guard let activeId = activeProfileId else { return nil }
            return profiles.first { $0.id == activeId }
        }
    }
    
    static func addProfile(_ profile: Profile) {
        var currentProfiles = profiles
        currentProfiles.append(profile)
        profiles = currentProfiles
    }
    
    static func updateProfile(_ profile: Profile) {
        var currentProfiles = profiles
        if let index = currentProfiles.firstIndex(where: { $0.id == profile.id }) {
            currentProfiles[index] = profile
            profiles = currentProfiles
        }
    }
    
    static func deleteProfile(_ profileId: String) {
        var currentProfiles = profiles
        currentProfiles.removeAll { $0.id == profileId }
        profiles = currentProfiles
        
        if activeProfileId == profileId {
            activeProfileId = currentProfiles.first?.id
        }
    }
    
    static func setActiveProfile(_ profileId: String) {
        activeProfileId = profileId
        var currentProfiles = profiles
        for i in 0..<currentProfiles.count {
            currentProfiles[i].isActive = currentProfiles[i].id == profileId
        }
        profiles = currentProfiles
    }
} 