import Foundation
import Combine

class ProfileViewModel: ObservableObject {
    @Published var profiles: [Profile] = []
    @Published var activeProfile: Profile?
    @Published var isLoading = false
    @Published var error: String?
    
    private let apiService: APIProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(apiService: APIProtocol = APIService.shared) {
        self.apiService = apiService
        print("ProfileViewModel: Инициализация")
        loadProfiles()
    }
    
    func loadProfiles() {
        print("ProfileViewModel: Загрузка профилей")
        isLoading = true
        error = nil
        
        Task {
            do {
                let loadedProfiles = try await apiService.getProfiles()
                print("ProfileViewModel: Получено профилей: \(loadedProfiles.count)")
                await MainActor.run {
                    self.profiles = loadedProfiles
                    ProfileManager.profiles = loadedProfiles
                    if let activeId = ProfileManager.activeProfileId {
                        self.activeProfile = loadedProfiles.first { $0.id == activeId }
                        print("ProfileViewModel: Активный профиль: \(self.activeProfile?.name ?? "нет")")
                    }
                    self.isLoading = false
                }
            } catch {
                print("ProfileViewModel: Ошибка загрузки профилей: \(error.localizedDescription)")
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func createProfile(name: String) async throws {
        print("ProfileViewModel: Создание профиля с именем: \(name)")
        isLoading = true
        error = nil
        
        do {
            let newProfile = try await apiService.createProfile(name: name)
            print("ProfileViewModel: Профиль успешно создан: \(newProfile.name)")
            await MainActor.run {
                self.profiles.append(newProfile)
                ProfileManager.profiles = self.profiles
                self.isLoading = false
                // Автоматически устанавливаем новый профиль как активный, если это первый профиль
                if self.profiles.count == 1 {
                    self.setActiveProfile(newProfile)
                }
            }
        } catch {
            print("ProfileViewModel: Ошибка создания профиля: \(error.localizedDescription)")
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
            throw error
        }
    }
    
    func updateProfile(_ profile: Profile) {
        print("ProfileViewModel: Обновление профиля: \(profile.name)")
        isLoading = true
        error = nil
        
        Task {
            do {
                let updatedProfile = try await apiService.updateProfile(profile)
                print("ProfileViewModel: Профиль успешно обновлен")
                await MainActor.run {
                    if let index = self.profiles.firstIndex(where: { $0.id == profile.id }) {
                        self.profiles[index] = updatedProfile
                    }
                    if self.activeProfile?.id == profile.id {
                        self.activeProfile = updatedProfile
                    }
                    ProfileManager.profiles = self.profiles
                    self.isLoading = false
                }
            } catch {
                print("ProfileViewModel: Ошибка обновления профиля: \(error.localizedDescription)")
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func deleteProfile(_ profile: Profile) {
        print("ProfileViewModel: Удаление профиля: \(profile.name)")
        isLoading = true
        error = nil
        
        Task {
            do {
                try await apiService.deleteProfile(id: profile.id)
                print("ProfileViewModel: Профиль успешно удален")
                await MainActor.run {
                    self.profiles.removeAll { $0.id == profile.id }
                    ProfileManager.profiles = self.profiles
                    if self.activeProfile?.id == profile.id {
                        self.activeProfile = self.profiles.first
                        ProfileManager.setActiveProfile(self.profiles.first?.id ?? "")
                    }
                    self.isLoading = false
                }
            } catch {
                print("ProfileViewModel: Ошибка удаления профиля: \(error.localizedDescription)")
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func setActiveProfile(_ profile: Profile) {
        print("ProfileViewModel: Установка активного профиля: \(profile.name)")
        ProfileManager.setActiveProfile(profile.id)
        Task {
            await MainActor.run {
                activeProfile = profile
                // Обновляем isActive для всех профилей в списке
                for i in 0..<profiles.count {
                    profiles[i].isActive = profiles[i].id == profile.id
                }
                ProfileManager.profiles = self.profiles
            }
        }
    }
} 