import SwiftUI
import Foundation

struct MainView: View {
    @StateObject private var viewModel = MixViewModel()
    @State private var showingFilter = false
    @State private var showingProfileView = false
    @Environment(\.colorScheme) var colorScheme
    
    init() {
        // Временно очищаем все профили для отладки проблемы с UserDefaults
        // ProfileManager.clearAllProfiles()
    }
    
    // Цветовая схема
    private let colors = (
        red: Color(hex: "FF0000"),
        orange: Color(hex: "FFA500"),
        darkBlue: Color(hex: "01081B")
    )
    
    var body: some View {
        NavigationView {
            MixListView(
                onEdit: viewModel.editMix,
                onDelete: viewModel.deleteMix
            )
            .environmentObject(viewModel)
            .searchable(text: $viewModel.searchText, prompt: "Поиск миксов")
            .navigationTitle("Миксы")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingProfileView = true }) {
                        Image(systemName: "person.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilter = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.addMix) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingFilter) {
                FilterView(
                    selectedTags: viewModel.selectedTags,
                    minStrength: Double(viewModel.minStrength),
                    maxStrength: Double(viewModel.maxStrength)
                )
                .environmentObject(viewModel)
            }
            .sheet(isPresented: $showingProfileView) {
                ProfileView()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .alert("Ошибка", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Поиск", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: MixViewModel
    
    // Цветовая схема
    private let colors = (
        red: Color(hex: "FE0000"),
        orange: Color(hex: "F5B769"),
        darkBlue: Color(hex: "01081B")
    )
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Заголовок
                    Text("О приложении")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(colors.darkBlue)
                        .padding(.top)
                    
                    // Описание
                    VStack(alignment: .leading, spacing: 12) {
                        Text("MTH - приложение для создания и хранения рецептов коктейлей.")
                            .foregroundColor(colors.darkBlue)
                        
                        Text("Основные возможности:")
                            .font(.headline)
                            .foregroundColor(colors.darkBlue)
                            .padding(.top)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(icon: "plus.circle", text: "Создание новых рецептов")
                            FeatureRow(icon: "pencil", text: "Редактирование существующих рецептов")
                            FeatureRow(icon: "tag", text: "Добавление тегов для удобной фильтрации")
                            FeatureRow(icon: "magnifyingglass", text: "Поиск по названию и составу")
                            FeatureRow(icon: "square.and.arrow.up", text: "Поделиться рецептом")
                        }
                    }
                    
                    // Версия приложения
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Версия")
                            .font(.headline)
                            .foregroundColor(colors.darkBlue)
                        
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    .padding(.top)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(colors.red)
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    // Цветовая схема
    private let colors = (
        red: Color(hex: "FE0000"),
        orange: Color(hex: "F5B769"),
        darkBlue: Color(hex: "01081B")
    )
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(colors.red)
                .frame(width: 24)
            
            Text(text)
                .foregroundColor(colors.darkBlue)
        }
    }
}

struct ProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var showingAddProfileAlert = false
    @State private var newProfileName = ""
    @State private var showingSettings = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isCreatingProfile = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Профили")) {
                    if profileViewModel.profiles.isEmpty {
                        Text("Нет профилей. Создайте первый профиль.")
                            .foregroundColor(.gray)
                    }
                    
                    ForEach(profileViewModel.profiles) { profile in
                        HStack {
                            Button(action: { profileViewModel.setActiveProfile(profile) }) {
                                Label(profile.name, systemImage: profile.isActive ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(profile.isActive ? .accentColor : .primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: { profileViewModel.deleteProfile(profile) }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Профили")
            .navigationBarItems(
                leading: Button("Готово") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: HStack {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                    }
                    Button(action: { showingAddProfileAlert = true }) {
                        Image(systemName: "plus")
                    }
                }
            )
            .alert("Добавить новый профиль", isPresented: $showingAddProfileAlert) {
                TextField("Название профиля", text: $newProfileName)
                Button("Отмена", role: .cancel) { 
                    newProfileName = ""
                    isCreatingProfile = false
                }
                Button("Добавить") {
                    if !newProfileName.isEmpty {
                        isCreatingProfile = true
                        Task {
                            do {
                                try await profileViewModel.createProfile(name: newProfileName)
                                newProfileName = ""
                                isCreatingProfile = false
                            } catch {
                                errorMessage = error.localizedDescription
                                showingError = true
                                isCreatingProfile = false
                            }
                        }
                    }
                }
                .disabled(isCreatingProfile)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .overlay {
                if profileViewModel.isLoading || isCreatingProfile {
                    ProgressView()
                }
            }
            .alert("Ошибка", isPresented: $showingError) {
                Button("OK") {
                    showingError = false
                }
            } message: {
                Text(errorMessage)
            }
        }
    }
}
