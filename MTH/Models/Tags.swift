import Foundation

class Tags {
    private static let userDefaults = UserDefaults.standard
    private static let tagsKey = "customTags"
    
    static var allTags: [String] {
        get {
            let defaultTags = ["Крепкий", "Сладкий", "Кислый", "Горький", "Фруктовый", "Цитрусовый", "Ягодный", "Травяной", "Пряный", "Дымный"]
            let customTags = userDefaults.stringArray(forKey: tagsKey) ?? []
            return defaultTags + customTags
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