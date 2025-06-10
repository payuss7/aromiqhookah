import Foundation

struct Mix: Identifiable, Codable, Equatable {
    let id: String
    let profileId: String
    var name: String
    var composition: String
    var strength: Int
    var notes: String
    var tags: [String]
    var guestTags: [String]
    var isInDevelopment: Bool
    
    init(id: String = UUID().uuidString, profileId: String, name: String, composition: String, strength: Int, notes: String, tags: [String], guestTags: [String] = [], isInDevelopment: Bool) {
        self.id = id
        self.profileId = profileId
        self.name = name
        self.composition = composition
        self.strength = strength
        self.notes = notes
        self.tags = tags
        self.guestTags = guestTags
        self.isInDevelopment = isInDevelopment
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case profileId
        case name
        case composition
        case strength
        case notes
        case tags
        case guestTags
        case isInDevelopment
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        profileId = try container.decode(String.self, forKey: .profileId)
        name = try container.decode(String.self, forKey: .name)
        composition = try container.decode(String.self, forKey: .composition)
        strength = try container.decode(Int.self, forKey: .strength)
        notes = try container.decode(String.self, forKey: .notes)
        tags = try container.decode([String].self, forKey: .tags)
        // Если guestTags отсутствует в JSON, используем пустой массив
        guestTags = try container.decodeIfPresent([String].self, forKey: .guestTags) ?? []
        isInDevelopment = try container.decode(Bool.self, forKey: .isInDevelopment)
    }
}