import Foundation

class GuestTags {
    private static let userDefaults = UserDefaults.standard
    private static let tagsKeyPrefix = "guestTags_"
    
    static func getTagsKey(for profileId: String) -> String {
        return tagsKeyPrefix + profileId
    }
    
    static func allTags(for profileId: String) -> [String] {
        let tagsKey = getTagsKey(for: profileId)
        return userDefaults.stringArray(forKey: tagsKey) ?? []
    }
    
    static func addTag(_ tag: String, for profileId: String) {
        let tagsKey = getTagsKey(for: profileId)
        var customTags = userDefaults.stringArray(forKey: tagsKey) ?? []
        if !customTags.contains(tag) {
            customTags.append(tag)
            userDefaults.set(customTags, forKey: tagsKey)
        }
    }
    
    static func removeTag(_ tag: String, for profileId: String) {
        let tagsKey = getTagsKey(for: profileId)
        var customTags = userDefaults.stringArray(forKey: tagsKey) ?? []
        customTags.removeAll { $0 == tag }
        userDefaults.set(customTags, forKey: tagsKey)
    }
    
    static func clearTags(for profileId: String) {
        let tagsKey = getTagsKey(for: profileId)
        userDefaults.removeObject(forKey: tagsKey)
    }
} 