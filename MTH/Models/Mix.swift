import Foundation

struct Mix: Identifiable, Codable, Equatable {
    let id: UUID
    let profileId: String
    var name: String
    var composition: String
    var strength: Int
    var notes: String
    var tags: [String]
    var guestTags: [String]
    var isInDevelopment: Bool
    
    init(id: UUID = UUID(), profileId: String, name: String, composition: String, strength: Int, notes: String, tags: [String], guestTags: [String] = [], isInDevelopment: Bool) {
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
        case id, profileId, name, composition, strength, notes, tags, guestTags, isInDevelopment
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
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