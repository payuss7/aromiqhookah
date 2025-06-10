import Foundation
import Combine
import SwiftUI
import UniformTypeIdentifiers // Добавляем для UIDocumentPickerDelegate

// Удаляем неправильный импорт
// import class MTH.APIService

class MixViewModel: NSObject, ObservableObject {
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
    let apiService: APIProtocol
    private var retryCount = 0
    private let maxRetries = 3
    
    // Новые вычисляемые свойства для всех тегов и тегов гостей
    var allTags: Set<String> {
        Set((readyMixes + developmentMixes).flatMap { $0.tags })
    }
    
    var allGuestTags: Set<String> {
        Set((readyMixes + developmentMixes).flatMap { $0.guestTags })
    }
    
    init(apiService: APIProtocol = APIService.shared) {
        self.apiService = apiService
        super.init()
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
        guard let activeProfile = ProfileManager.activeProfile else {
            print("Нет активного профиля")
            return
        }
        isLoading = true
        error = nil
        do {
            let mixes = try await apiService.fetchMixes()
            let filtered = mixes.filter { $0.profileId == activeProfile.id }
            self.readyMixes = filtered.filter { !$0.isInDevelopment }
            self.developmentMixes = filtered.filter { $0.isInDevelopment }
            self.isLoading = false
        } catch {
            print("Ошибка загрузки миксов: \(error)")
            self.error = error.localizedDescription
            self.isLoading = false
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
    
    func saveMix(_ mix: Mix) async throws {
        do {
            try await apiService.saveMix(mix)
            await loadMixes()
        } catch {
            print("Ошибка сохранения микса: \(error)")
            throw error
        }
    }
    
    func updateMix(_ mix: Mix) async throws {
        do {
            try await apiService.updateMix(mix)
            await loadMixes()
        } catch {
            print("Ошибка обновления микса: \(error)")
            throw error
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
    
    // Методы для управления тегами
    func addTag(_ tag: String) {
        if !tag.isEmpty && !self.selectedTags.contains(tag) {
            self.selectedTags.insert(tag)
        }
    }
    
    func removeTag(_ tag: String) {
        self.selectedTags.remove(tag)
    }
    
    func addGuestTag(_ tag: String) {
        if !tag.isEmpty && !self.selectedGuestTags.contains(tag) {
            self.selectedGuestTags.insert(tag)
        }
    }
    
    func removeGuestTag(_ tag: String) {
        self.selectedGuestTags.remove(tag)
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
        guard let activeProfile = ProfileManager.activeProfile else {
            self.error = "Пожалуйста, создайте и выберите профиль перед созданием микса"
            return
        }
        print("Добавление нового микса")
        let newMix = Mix(
            id: UUID(),
            profileId: activeProfile.id,
            name: "Новый микс",
            composition: "",
            strength: 5,
            notes: "",
            tags: [],
            guestTags: [],
            isInDevelopment: true
        )
        Task {
            do {
                try await saveMix(newMix)
            } catch {
                print("Ошибка при добавлении микса: \(error)")
                self.error = "Ошибка при добавлении микса: \(error.localizedDescription)"
            }
        }
    }
    
    func getMixById(_ id: UUID) -> Mix? {
        if let mix = readyMixes.first(where: { $0.id == id }) {
            return mix
        }
        return developmentMixes.first(where: { $0.id == id })
    }
    
    func editMix(_ mix: Mix) {
        print("Редактирование микса: \(mix.name)")
        // Открытие экрана редактирования реализуется во View
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
            let existingIds = Set(readyMixes.map { $0.id } + developmentMixes.map { $0.id })
            let newMixes = importedMixes.filter { !existingIds.contains($0.id) }
            print("Новых миксов для добавления: \(newMixes.count)")
            for newMix in newMixes {
                Task {
                    let mixToSave = newMix // Capture as a constant
                    try? await self.saveMix(mixToSave)
                }
            }
        } catch {
            print("Ошибка при импорте миксов: \(error)")
        }
    }
    
    func moveMix(_ mix: Mix) {
        Task {
            let mixToUpdate = mix // Capture as a constant
            var updatedMix = mixToUpdate
            updatedMix.isInDevelopment.toggle()
            do {
                try await updateMix(updatedMix)
            } catch {
                print("Ошибка при перемещении микса: \(error)")
            }
        }
    }
}

// MARK: - Document Picker Coordinator
class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate {
    let onPick: (URL) -> Void
    let onError: (String) -> Void
    
    init(onPick: @escaping (URL) -> Void, onError: @escaping (String) -> Void) {
        self.onPick = onPick
        self.onError = onError
        super.init()
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            onError("Не выбран файл")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            onPick(url)
        } catch {
            onError("Ошибка при импорте файла: \(error.localizedDescription)")
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Выбор файла отменен")
    }
}
