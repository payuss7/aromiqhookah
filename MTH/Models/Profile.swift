import Foundation

extension Date {
    var iso8601: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: self)
    }
}

struct Profile: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var isActive: Bool
    let createdAt: String
    let updatedAt: String
    let __v: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case isActive
        case createdAt
        case updatedAt
        case __v
    }
    
    init(id: String = UUID().uuidString, name: String, isActive: Bool = false, createdAt: String = Date().iso8601, updatedAt: String = Date().iso8601, __v: Int = 0) {
        self.id = id
        self.name = name
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.__v = __v
    }
}

class ProfileManager {
    private static let userDefaults = UserDefaults.standard
    private static let profilesKey = "profiles"
    private static let activeProfileIdKey = "activeProfileId"
    
    static var profiles: [Profile] {
        get {
            print("ProfileManager: Получение профилей из UserDefaults")
            guard let data = userDefaults.data(forKey: profilesKey) else {
                print("ProfileManager: Данные профилей в UserDefaults отсутствуют.")
                return []
            }
            do {
                let profiles = try JSONDecoder().decode([Profile].self, from: data)
                print("ProfileManager: Получено \(profiles.count) профилей.")
                return profiles
            } catch {
                print("ProfileManager: Ошибка декодирования профилей из UserDefaults: \(error.localizedDescription)")
                return []
            }
        }
        set {
            print("ProfileManager: Сохранение \(newValue.count) профилей в UserDefaults")
            do {
                let data = try JSONEncoder().encode(newValue)
                userDefaults.set(data, forKey: profilesKey)
            } catch {
                print("ProfileManager: Ошибка кодирования профилей для сохранения в UserDefaults: \(error.localizedDescription)")
            }
        }
    }
    
    static var activeProfileId: String? {
        get {
            let id = userDefaults.string(forKey: activeProfileIdKey)
            print("ProfileManager: Получение activeProfileId: \(id ?? "nil")")
            return id
        }
        set {
            print("ProfileManager: Установка activeProfileId: \(newValue ?? "nil")")
            userDefaults.set(newValue, forKey: activeProfileIdKey)
        }
    }
    
    static var activeProfile: Profile? {
        get {
            print("ProfileManager: Получение активного профиля.")
            guard let activeId = activeProfileId else {
                print("ProfileManager: activeProfileId отсутствует.")
                return nil
            }
            let foundProfile = profiles.first { $0.id == activeId }
            print("ProfileManager: Найден активный профиль: \(foundProfile?.name ?? "nil")")
            return foundProfile
        }
    }
    
    static func addProfile(_ profile: Profile) {
        print("ProfileManager: Добавление профиля: \(profile.name)")
        var currentProfiles = profiles
        currentProfiles.append(profile)
        profiles = currentProfiles
    }
    
    static func updateProfile(_ profile: Profile) {
        print("ProfileManager: Обновление профиля: \(profile.name)")
        var currentProfiles = profiles
        if let index = currentProfiles.firstIndex(where: { $0.id == profile.id }) {
            currentProfiles[index] = profile
            profiles = currentProfiles
        }
    }
    
    static func deleteProfile(_ profileId: String) {
        print("ProfileManager: Удаление профиля с ID: \(profileId)")
        var currentProfiles = profiles
        currentProfiles.removeAll { $0.id == profileId }
        profiles = currentProfiles
        
        if activeProfileId == profileId {
            print("ProfileManager: Удаленный профиль был активным. Сброс активного профиля.")
            activeProfileId = currentProfiles.first?.id
        }
    }
    
    static func setActiveProfile(_ profileId: String) {
        print("ProfileManager: Установка активного профиля с ID: \(profileId)")
        activeProfileId = profileId
        // Логика обновления isActive перемещена в ProfileViewModel
        // var currentProfiles = profiles
        // for i in 0..<currentProfiles.count {
        //    currentProfiles[i].isActive = currentProfiles[i].id == profileId
        // }
        // profiles = currentProfiles
        print("ProfileManager: Активный профиль установлен и сохранен.")
    }
    
    static func clearAllProfiles() {
        print("ProfileManager: Очистка всех профилей и активного ID из UserDefaults.")
        userDefaults.removeObject(forKey: profilesKey)
        userDefaults.removeObject(forKey: activeProfileIdKey)
    }
} 