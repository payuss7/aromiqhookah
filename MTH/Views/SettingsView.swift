import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewModel: MixViewModel
    @State private var newTag = ""
    @State private var showingExportSheet = false
    @State private var showingImportPicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var newGuestTag = ""
    @State private var serverURL: String = UserDefaults.standard.string(forKey: "serverURL") ?? ""
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var showingAddProfileAlert = false
    @State private var newProfileName: String = ""
    
    // Цветовая схема
    private let colors = (
        red: Color(hex: "FE0000"),
        orange: Color(hex: "F5B769"),
        darkBlue: Color(hex: "01081B")
    )
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Настройки сервера")) {
                    TextField("URL сервера", text: $serverURL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Button("Сохранить URL") {
                        saveServerURL()
                    }
                }
                
                Section(header: Text("Управление профилями")) {
                    if profileViewModel.profiles.isEmpty {
                        Text("Нет профилей. Создайте первый профиль.")
                            .foregroundColor(.gray)
                    }
                    
                    ForEach(profileViewModel.profiles) { profile in
                        HStack {
                            Button(action: { profileViewModel.setActiveProfile(profile) }) {
                                Label(profile.name, systemImage: profile.isActive ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(profile.isActive ? .accentColor : .primary)
                            }
                            Spacer()
                            Button(action: { profileViewModel.deleteProfile(profile) }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    Button("Добавить профиль") {
                        showingAddProfileAlert = true
                    }
                }
                
                Section(header: Text("Управление тегами")) {
                    VStack(alignment: .leading) {
                        Text("Все теги миксов:")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(Array(viewModel.allTags), id: \.self) { tag in
                                    TagButton(
                                        title: tag,
                                        isSelected: true,
                                        action: {},
                                        isGuestTag: false
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    HStack {
                        TextField("Новый тег", text: $newTag)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Добавить") {
                            addTag()
                        }
                        .disabled(newTag.isEmpty)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Все теги гостей:")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(Array(viewModel.allGuestTags), id: \.self) { tag in
                                    TagButton(
                                        title: tag,
                                        isSelected: true,
                                        action: {},
                                        isGuestTag: true
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    HStack {
                        TextField("Новый тег гостя", text: $newGuestTag)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Добавить") {
                            addGuestTag()
                        }
                        .disabled(newGuestTag.isEmpty)
                    }
                }
                
                Section(header: Text("Импорт/Экспорт")) {
                    Button("Экспортировать данные") {
                        if let data = viewModel.exportMixesData() {
                            let activityVC = UIActivityViewController(activityItems: [data], applicationActivities: nil)
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let window = windowScene.windows.first,
                               let rootVC = window.rootViewController {
                                activityVC.popoverPresentationController?.sourceView = rootVC.view
                                rootVC.present(activityVC, animated: true)
                            }
                        }
                    }
                    
                    Button("Импортировать данные") {
                        showingImportPicker = true
                    }
                }
            }
            .navigationTitle("Настройки")
            .navigationBarItems(trailing: Button("Готово") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingImportPicker) {
                DocumentPicker(
                    onPick: { url in
                        do {
                            let data = try Data(contentsOf: url)
                            viewModel.importMixesData(data)
                        } catch {
                            alertMessage = "Ошибка при импорте: \(error.localizedDescription)"
                            showingAlert = true
                        }
                    },
                    showAlert: $showingAlert,
                    alertMessage: $alertMessage
                )
            }
            .alert("Ошибка", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
            }
            .alert("Добавить новый профиль", isPresented: $showingAddProfileAlert) {
                TextField("Название профиля", text: $newProfileName)
                Button("Отмена", role: .cancel) { newProfileName = "" }
                Button("Добавить") {
                    if !newProfileName.isEmpty {
                        Task {
                            do {
                                try await profileViewModel.createProfile(name: newProfileName)
                                newProfileName = ""
                            } catch {
                                alertMessage = error.localizedDescription
                                showingAlert = true
                            }
                        }
                    }
                }
            }
        }
        .accentColor(colors.red)
    }
    
    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tag.isEmpty {
            viewModel.addTag(tag)
            newTag = ""
        }
    }
    
    private func deleteTag(_ tag: String) {
        viewModel.removeTag(tag)
    }
    
    private func addGuestTag() {
        let tag = newGuestTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tag.isEmpty {
            viewModel.addGuestTag(tag)
            newGuestTag = ""
        }
    }
    
    private func deleteGuestTag(_ tag: String) {
        viewModel.removeGuestTag(tag)
    }
    
    private func saveServerURL() {
        // Проверяем, что URL не пустой
        guard !serverURL.isEmpty else {
            alertMessage = "URL сервера не может быть пустым"
            showingAlert = true
            return
        }
        
        // Проверяем, что URL начинается с http:// или https://
        guard serverURL.hasPrefix("http://") || serverURL.hasPrefix("https://") else {
            alertMessage = "URL должен начинаться с http:// или https://"
            showingAlert = true
            return
        }
        
        // Добавляем /api в конец URL, если его нет
        if !serverURL.hasSuffix("/api") {
            serverURL += "/api"
        }
        
        // Сохраняем URL
        viewModel.apiService.setServerURL(serverURL)
        UserDefaults.standard.set(serverURL, forKey: "serverURL")
        alertMessage = "URL сервера успешно обновлен"
        showingAlert = true
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    @Binding var showAlert: Bool
    @Binding var alertMessage: String
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> DocumentPickerCoordinator {
        DocumentPickerCoordinator(
            onPick: { url in
                onPick(url)
            },
            onError: { error in
                alertMessage = error
                showAlert = true
            }
        )
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(MixViewModel())
            .environmentObject(ProfileViewModel())
    }
}

struct MixDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    init(configuration: ReadConfiguration) throws {
        url = URL(fileURLWithPath: "")
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try Data(contentsOf: url)
        return FileWrapper(regularFileWithContents: data)
    }
} 