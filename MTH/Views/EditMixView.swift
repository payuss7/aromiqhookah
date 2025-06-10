import SwiftUI
import Foundation

struct EditMixView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: MixViewModel
    @StateObject private var profileViewModel = ProfileViewModel()
    
    let mix: Mix?
    
    @State private var name: String
    @State private var composition: String
    @State private var notes: String
    @State private var tags: [String]
    @State private var guestTags: [String]
    @State private var strength: Double
    @State private var isInDevelopment: Bool
    @State private var newTag: String = ""
    @State private var newGuestTag: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    init(mix: Mix?) {
        self.mix = mix
        _name = State(initialValue: mix?.name ?? "")
        _composition = State(initialValue: mix?.composition ?? "")
        _notes = State(initialValue: mix?.notes ?? "")
        _tags = State(initialValue: mix?.tags ?? [])
        _guestTags = State(initialValue: mix?.guestTags ?? [])
        _strength = State(initialValue: Double(mix?.strength ?? 0))
        _isInDevelopment = State(initialValue: mix?.isInDevelopment ?? true)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Основная информация")) {
                    TextField("Название микса", text: $name)
                    TextField("Состав", text: $composition)
                    TextField("Заметки", text: $notes)
                    HStack {
                        Text("Крепость: \(Int(strength))/10")
                        Slider(value: $strength, in: 0...10, step: 1)
                    }
                    Toggle("В разработке", isOn: $isInDevelopment)
                }
                
                Section(header: Text("Теги")) {
                    HStack {
                        TextField("Новый тег", text: $newTag)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button(action: addTag) {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newTag.isEmpty)
                    }
                    ForEach(tags, id: \.self) { tag in
                        HStack {
                            Text(tag)
                            Spacer()
                            Button(action: { removeTag(tag) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                Section(header: Text("Теги гостей")) {
                    HStack {
                        TextField("Новый тег гостя", text: $newGuestTag)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button(action: addGuestTag) {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newGuestTag.isEmpty)
                    }
                    ForEach(guestTags, id: \.self) { tag in
                        HStack {
                            Text(tag)
                            Spacer()
                            Button(action: { removeGuestTag(tag) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle(mix == nil ? "Новый микс" : "Редактирование")
            .navigationBarItems(
                leading: Button("Отмена") {
                    dismiss()
                },
                trailing: Button("Сохранить") {
                    saveMix()
                }
                .disabled(name.isEmpty)
            )
            .alert("Ошибка", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tag.isEmpty && !tags.contains(tag) {
            tags.append(tag)
            newTag = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    private func addGuestTag() {
        let tag = newGuestTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tag.isEmpty && !guestTags.contains(tag) {
            guestTags.append(tag)
            newGuestTag = ""
        }
    }
    
    private func removeGuestTag(_ tag: String) {
        guestTags.removeAll { $0 == tag }
    }
    
    private func saveMix() {
        guard let activeProfile = profileViewModel.activeProfile ?? ProfileManager.activeProfile else {
            errorMessage = "Не выбран активный профиль"
            showingError = true
            return
        }
        let updatedMix = Mix(
            id: mix?.id ?? UUID(),
            profileId: activeProfile.id,
            name: name,
            composition: composition,
            strength: Int(strength),
            notes: notes,
            tags: tags,
            guestTags: guestTags,
            isInDevelopment: isInDevelopment
        )
        Task {
            do {
                if mix == nil {
                    try await viewModel.saveMix(updatedMix)
                } else {
                    try await viewModel.updateMix(updatedMix)
                }
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

struct EditMixView_Previews: PreviewProvider {
    static var previews: some View {
        EditMixView(mix: nil)
            .environmentObject(MixViewModel())
    }
}
