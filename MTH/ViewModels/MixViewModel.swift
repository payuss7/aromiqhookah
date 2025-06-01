import Foundation
import Combine
import SwiftUI

// Удаляем неправильный импорт
// import class MTH.APIService

class MixViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedTags: Set<String> = []
    @Published var selectedGuestTags: Set<String> = []
    @Published var readyMixes: [Mix] = []
    @Published var developmentMixes: [Mix] = []
    @Published var minStrength: Int = 0
    @Published var maxStrength: Int = 10
    @Published var isLoading = false
    @Published var error: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let apiService: APIProtocol
    private var retryCount = 0
    private let maxRetries = 3
    
    init(apiService: APIProtocol = APIService.shared) {
        self.apiService = apiService
        print("Инициализация MixViewModel")
        setupBindings()
        Task {
            await loadMixes()
        }
    }
    
    private func setupBindings() {
        Publishers.CombineLatest4(
            $searchText.debounce(for: .milliseconds(300), scheduler: RunLoop.main),
            $selectedTags,
            $selectedGuestTags,
            Publishers.CombineLatest($minStrength, $maxStrength)
        )
        .sink { [weak self] _ in
            self?.filterMixes()
        }
        .store(in: &cancellables)
    }
    
    @MainActor
    func loadMixes() async {
        guard !isLoading else {
            print("Загрузка уже выполняется, пропускаем")
            return
        }
        
        isLoading = true
        error = nil
        print("Начало загрузки миксов. Попытка \(retryCount + 1) из \(maxRetries)")
        
        do {
            let mixes = try await apiService.fetchMixes()
            readyMixes = mixes.filter { !$0.isInDevelopment }
            developmentMixes = mixes.filter { $0.isInDevelopment }
            print("Загружено миксов: \(mixes.count)")
            retryCount = 0 // Сбрасываем счетчик при успешной загрузке
            isLoading = false
        } catch let apiError as APIError {
            print("Получена ошибка API: \(apiError.localizedDescription)")
            
            if case .serverWakingUp = apiError {
                if retryCount < maxRetries {
                    retryCount += 1
                    print("Сервер просыпается. Попытка \(retryCount) из \(maxRetries)")
                    isLoading = false // Сбрасываем флаг загрузки перед ожиданием
                    try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 секунд
                    await loadMixes()
                } else {
                    print("Превышено максимальное количество попыток")
                    self.error = "Не удалось подключиться к серверу после \(maxRetries) попыток. Проверьте подключение к интернету и попробуйте позже."
                    isLoading = false
                }
            } else {
                print("Другая ошибка API: \(apiError.localizedDescription)")
                self.error = apiError.localizedDescription
                isLoading = false
            }
        } catch {
            print("Неизвестная ошибка: \(error)")
            self.error = "Неизвестная ошибка: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func filterMixes() {
        let allMixes = readyMixes + developmentMixes
        print("Фильтрация миксов. Всего миксов: \(allMixes.count)")
        
        let filteredMixes = allMixes.filter { mix in
            let matchesSearch = searchText.isEmpty ||
                mix.name.localizedCaseInsensitiveContains(searchText) ||
                mix.composition.localizedCaseInsensitiveContains(searchText) ||
                mix.notes.localizedCaseInsensitiveContains(searchText)
            
            let matchesTags = selectedTags.isEmpty ||
                selectedTags.allSatisfy { selectedTag in
                    mix.tags.contains(selectedTag)
                }
            
            let matchesGuestTags = selectedGuestTags.isEmpty ||
                selectedGuestTags.allSatisfy { selectedTag in
                    mix.guestTags.contains(selectedTag)
                }
            
            let matchesStrength = mix.strength >= minStrength && mix.strength <= maxStrength
            
            return matchesSearch && matchesTags && matchesGuestTags && matchesStrength
        }
        
        readyMixes = filteredMixes.filter { !$0.isInDevelopment }
        developmentMixes = filteredMixes.filter { $0.isInDevelopment }
        print("После фильтрации: готовых миксов: \(readyMixes.count), в разработке: \(developmentMixes.count)")
    }
    
    func saveMix(_ mix: Mix) {
        Task {
            do {
                if mix.id == UUID() {
                    try await apiService.saveMix(mix)
                } else {
                    try await apiService.updateMix(mix)
                }
                await loadMixes()
            } catch {
                print("Ошибка сохранения микса: \(error)")
            }
        }
    }
    
    func deleteMix(_ mix: Mix) {
        Task {
            do {
                try await apiService.deleteMix(mix)
                await loadMixes()
            } catch {
                print("Ошибка удаления микса: \(error)")
            }
        }
    }
    
    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
        filterMixes()
    }
    
    func toggleGuestTag(_ tag: String) {
        if selectedGuestTags.contains(tag) {
            selectedGuestTags.remove(tag)
        } else {
            selectedGuestTags.insert(tag)
        }
        filterMixes()
    }
    
    func applyFilters(selectedTags: Set<String>, selectedGuestTags: Set<String>, minStrength: Int, maxStrength: Int) {
        self.selectedTags = selectedTags
        self.selectedGuestTags = selectedGuestTags
        self.minStrength = minStrength
        self.maxStrength = maxStrength
    }
    
    func clearFilters() {
        searchText = ""
        selectedTags.removeAll()
        selectedGuestTags.removeAll()
        minStrength = 0
        maxStrength = 10
    }
    
    func getMixText(_ mix: Mix) -> String {
        var text = "\(mix.name)\n"
        text += "Крепость: \(mix.strength)/10\n\n"
        text += "Состав:\n\(mix.composition)\n"
        
        if !mix.notes.isEmpty {
            text += "\nЗаметки:\n\(mix.notes)\n"
        }
        
        if !mix.tags.isEmpty {
            text += "\nТеги: \(mix.tags.joined(separator: ", "))\n"
        }
        
        if !mix.guestTags.isEmpty {
            text += "\nГости: \(mix.guestTags.joined(separator: ", "))\n"
        }
        
        return text
    }
    
    func addMix() {
        print("Добавление нового микса")
        let newMix = Mix(
            name: "Новый микс",
            composition: "",
            strength: 5,
            notes: "",
            tags: [],
            isInDevelopment: true
        )
        saveMix(newMix)
    }
    
    func getMixById(_ id: UUID) -> Mix? {
        if let mix = readyMixes.first(where: { $0.id == id }) {
            return mix
        }
        return developmentMixes.first(where: { $0.id == id })
    }
    
    func editMix(_ mix: Mix) {
        print("Редактирование микса: \(mix.name)")
        saveMix(mix)
    }
    
    func exportMixesData() -> Data? {
        let allMixes = readyMixes + developmentMixes
        print("Экспорт миксов, всего: \(allMixes.count)")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(allMixes)
            return data
        } catch {
            print("Ошибка при экспорте миксов: \(error)")
            return nil
        }
    }
    
    func importMixesData(_ data: Data) {
        print("Импорт миксов")
        do {
            let decoder = JSONDecoder()
            let importedMixes = try decoder.decode([Mix].self, from: data)
            print("Импортировано миксов: \(importedMixes.count)")
            
            // Добавляем только новые миксы
            let existingIds = Set(readyMixes.map { $0.id } + developmentMixes.map { $0.id })
            let newMixes = importedMixes.filter { !existingIds.contains($0.id) }
            print("Новых миксов для добавления: \(newMixes.count)")
            
            for mix in newMixes {
                Task {
                    await saveMix(mix)
                }
            }
        } catch {
            print("Ошибка при импорте миксов: \(error)")
        }
    }
    
    func moveMix(_ mix: Mix) {
        var updatedMix = mix
        updatedMix.isInDevelopment.toggle()
        saveMix(updatedMix)
    }
}
