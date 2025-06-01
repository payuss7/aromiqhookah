import Foundation

class MixService {
    private let userDefaults = UserDefaults.standard
    private let readyMixesKey = "readyMixes"
    private let developmentMixesKey = "developmentMixes"
    
    func getReadyMixes() -> [Mix] {
        guard let data = userDefaults.data(forKey: readyMixesKey) else {
            print("Нет данных для готовых миксов")
            return []
        }
        let mixes = (try? JSONDecoder().decode([Mix].self, from: data)) ?? []
        print("Загружено готовых миксов: \(mixes.count)")
        return mixes
    }
    
    func getDevelopmentMixes() -> [Mix] {
        guard let data = userDefaults.data(forKey: developmentMixesKey) else {
            print("Нет данных для миксов в разработке")
            return []
        }
        let mixes = (try? JSONDecoder().decode([Mix].self, from: data)) ?? []
        print("Загружено миксов в разработке: \(mixes.count)")
        return mixes
    }
    
    func getAllMixes() -> [Mix] {
        return getReadyMixes() + getDevelopmentMixes()
    }
    
    func getMixById(_ id: UUID) -> Mix? {
        return getAllMixes().first { $0.id == id }
    }
    
    func saveMix(_ mix: Mix) {
        print("Сохранение микса: \(mix.name), ID: \(mix.id), статус: \(mix.isInDevelopment ? "в разработке" : "готовый")")
        var readyMixes = getReadyMixes()
        var developmentMixes = getDevelopmentMixes()
        
        if mix.isInDevelopment {
            if let index = developmentMixes.firstIndex(where: { $0.id == mix.id }) {
                developmentMixes[index] = mix
                print("Обновлен существующий микс в разработке")
            } else {
                developmentMixes.append(mix)
                print("Добавлен новый микс в разработку")
            }
        } else {
            if let index = readyMixes.firstIndex(where: { $0.id == mix.id }) {
                readyMixes[index] = mix
                print("Обновлен существующий готовый микс")
            } else {
                readyMixes.append(mix)
                print("Добавлен новый готовый микс")
            }
        }
        
        saveMixes(readyMixes: readyMixes, developmentMixes: developmentMixes)
    }
    
    func deleteMix(_ mix: Mix) {
        print("Удаление микса: \(mix.name), ID: \(mix.id)")
        var readyMixes = getReadyMixes()
        var developmentMixes = getDevelopmentMixes()
        
        if mix.isInDevelopment {
            developmentMixes.removeAll { $0.id == mix.id }
            print("Удален микс из разработки")
        } else {
            readyMixes.removeAll { $0.id == mix.id }
            print("Удален готовый микс")
        }
        
        saveMixes(readyMixes: readyMixes, developmentMixes: developmentMixes)
    }
    
    func saveAllMixes(_ mixes: [Mix]) {
        print("Сохранение всех миксов, всего: \(mixes.count)")
        let readyMixes = mixes.filter { !$0.isInDevelopment }
        let developmentMixes = mixes.filter { $0.isInDevelopment }
        print("Готовых миксов: \(readyMixes.count), в разработке: \(developmentMixes.count)")
        saveMixes(readyMixes: readyMixes, developmentMixes: developmentMixes)
    }
    
    private func saveMixes(readyMixes: [Mix], developmentMixes: [Mix]) {
        if let readyData = try? JSONEncoder().encode(readyMixes) {
            userDefaults.set(readyData, forKey: readyMixesKey)
            print("Сохранены готовые миксы: \(readyMixes.count)")
        } else {
            print("Ошибка при сохранении готовых миксов")
        }
        
        if let developmentData = try? JSONEncoder().encode(developmentMixes) {
            userDefaults.set(developmentData, forKey: developmentMixesKey)
            print("Сохранены миксы в разработке: \(developmentMixes.count)")
        } else {
            print("Ошибка при сохранении миксов в разработке")
        }
        
        // Принудительно сохраняем изменения
        userDefaults.synchronize()
    }
}
