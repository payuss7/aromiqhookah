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
    
    // Цветовая схема
    private let colors = (
        red: Color(hex: "FE0000"),
        orange: Color(hex: "F5B769"),
        darkBlue: Color(hex: "01081B")
    )
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Управление данными")) {
                    Button(action: {
                        if let data = viewModel.exportMixesData() {
                            let temporaryDirectoryURL = FileManager.default.temporaryDirectory
                            let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent("mixes.json")
                            do {
                                try data.write(to: temporaryFileURL)
                                let activityVC = UIActivityViewController(
                                    activityItems: [temporaryFileURL],
                                    applicationActivities: nil
                                )
                                
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let window = windowScene.windows.first,
                                   let rootVC = window.rootViewController {
                                    activityVC.popoverPresentationController?.sourceView = rootVC.view
                                    rootVC.present(activityVC, animated: true)
                                }
                            } catch {
                                alertMessage = "Ошибка при экспорте: \(error.localizedDescription)"
                                showingAlert = true
                            }
                        } else {
                            alertMessage = "Ошибка при экспорте миксов"
                            showingAlert = true
                        }
                    }) {
                        Label("Экспорт миксов", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: {
                        showingImportPicker = true
                    }) {
                        Label("Импорт миксов", systemImage: "square.and.arrow.down")
                    }
                }
                
                Section(header: Text("Управление тегами")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Теги")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : colors.darkBlue)
                        
                        ScrollView {
                            FlowLayout(spacing: 8) {
                                ForEach(Array(Tags.allTags), id: \.self) { tag in
                                    TagButton(
                                        title: tag,
                                        isSelected: true,
                                        action: { deleteTag(tag) },
                                        isGuestTag: false
                                    )
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        
                        HStack {
                            TextField("Новый тег", text: $newTag)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Button(action: addTag) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(colors.red)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Гости")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : colors.darkBlue)
                        
                        ScrollView {
                            FlowLayout(spacing: 8) {
                                ForEach(Array(GuestTags.allTags), id: \.self) { tag in
                                    TagButton(
                                        title: tag,
                                        isSelected: true,
                                        action: { deleteGuestTag(tag) },
                                        isGuestTag: true
                                    )
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        
                        HStack {
                            TextField("Новый гость", text: $newGuestTag)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Button(action: addGuestTag) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(colors.red)
                            }
                        }
                    }
                }
                
                Section(header: Text("Настройки сервера")) {
                    TextField("URL сервера", text: $serverURL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Button("Сохранить") {
                        saveServerURL()
                    }
                }
                
                Section(header: Text("О приложении")) {
                    Text("MTH - Менеджер табачных миксов")
                    Text("Версия 1.0")
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(colors.red)
                }
            }
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
        }
        .accentColor(colors.red)
    }
    
    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tag.isEmpty {
            Tags.addTag(tag)
            newTag = ""
        }
    }
    
    private func deleteTag(_ tag: String) {
        Tags.removeTag(tag)
    }
    
    private func addGuestTag() {
        let tag = newGuestTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tag.isEmpty {
            GuestTags.addTag(tag)
            newGuestTag = ""
        }
    }
    
    private func deleteGuestTag(_ tag: String) {
        GuestTags.removeTag(tag)
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
        APIService.shared.setServerURL(serverURL)
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
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                parent.alertMessage = "Не удалось получить файл"
                parent.showAlert = true
                return
            }
            
            // Проверяем, что файл доступен для чтения
            guard url.startAccessingSecurityScopedResource() else {
                parent.alertMessage = "Нет доступа к файлу"
                parent.showAlert = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            parent.onPick(url)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // Пользователь отменил выбор файла
            print("Выбор файла отменен")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(MixViewModel())
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