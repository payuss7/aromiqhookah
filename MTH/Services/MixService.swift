import Foundation

class MixService {
    private static let userDefaults = UserDefaults.standard
    private static let mixesKeyPrefix = "mixes_"
    
    static func getMixesKey(for profileId: String) -> String {
        return mixesKeyPrefix + profileId
    }
    
    static func getMixes(for profileId: String) -> [Mix] {
        let mixesKey = getMixesKey(for: profileId)
        guard let data = userDefaults.data(forKey: mixesKey) else { return [] }
        do {
            return try JSONDecoder().decode([Mix].self, from: data)
        } catch {
            print("Ошибка декодирования миксов: \(error)")
            return []
        }
    }
    
    static func saveMix(_ mix: Mix, for profileId: String) {
        let mixesKey = getMixesKey(for: profileId)
        var mixes = getMixes(for: profileId)
        
        if let index = mixes.firstIndex(where: { $0.id == mix.id }) {
            mixes[index] = mix
        } else {
            mixes.append(mix)
        }
        
        do {
            let data = try JSONEncoder().encode(mixes)
            userDefaults.set(data, forKey: mixesKey)
        } catch {
            print("Ошибка сохранения микса: \(error)")
        }
    }
    
    static func deleteMix(_ mixId: String, for profileId: String) {
        let mixesKey = getMixesKey(for: profileId)
        var mixes = getMixes(for: profileId)
        mixes.removeAll { $0.id == mixId }
        
        do {
            let data = try JSONEncoder().encode(mixes)
            userDefaults.set(data, forKey: mixesKey)
        } catch {
            print("Ошибка удаления микса: \(error)")
        }
    }
    
    static func clearMixes(for profileId: String) {
        let mixesKey = getMixesKey(for: profileId)
        userDefaults.removeObject(forKey: mixesKey)
    }
}
