import Foundation

class GuestTags {
    private static let userDefaults = UserDefaults.standard
    private static let tagsKey = "guestTags"
    
    static var allTags: [String] {
        get {
            let customTags = userDefaults.stringArray(forKey: tagsKey) ?? []
            return customTags
        }
    }
    
    static func addTag(_ tag: String) {
        var customTags = userDefaults.stringArray(forKey: tagsKey) ?? []
        customTags.append(tag)
        userDefaults.set(customTags, forKey: tagsKey)
    }
    
    static func removeTag(_ tag: String) {
        var customTags = userDefaults.stringArray(forKey: tagsKey) ?? []
        customTags.removeAll { $0 == tag }
        userDefaults.set(customTags, forKey: tagsKey)
    }
} 