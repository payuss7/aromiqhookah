import SwiftUI
import Foundation

struct EditMixView: View {
    let mix: Mix?
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: MixViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var name: String
    @State private var composition: String
    @State private var strength: Double
    @State private var notes: String
    @State private var selectedTags: Set<String>
    @State private var selectedGuestTags: Set<String>
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(mix: Mix?) {
        self.mix = mix
        _name = State(initialValue: mix?.name ?? "")
        _composition = State(initialValue: mix?.composition ?? "")
        _strength = State(initialValue: Double(mix?.strength ?? 5))
        _notes = State(initialValue: mix?.notes ?? "")
        _selectedTags = State(initialValue: Set(mix?.tags ?? []))
        _selectedGuestTags = State(initialValue: Set(mix?.guestTags ?? []))
    }
    
    // Цветовая схема
    private let colors = (
        red: Color(hex: "FF0000"),
        orange: Color(hex: "FFA500"),
        darkBlue: Color(hex: "01081B")
    )
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Основная информация")) {
                    TextField("Название", text: $name)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .autocapitalization(.words)
                    
                    VStack(alignment: .leading) {
                        Text("Состав")
                            .foregroundColor(colorScheme == .dark ? .white : colors.darkBlue)
                        TextEditor(text: $composition)
                            .frame(minHeight: 100)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .autocapitalization(.sentences)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Крепость: \(Int(strength))")
                            .foregroundColor(colorScheme == .dark ? .white : colors.darkBlue)
                        Slider(value: $strength, in: 1...10, step: 1)
                            .accentColor(colors.red)
                    }
                }
                
                Section(header: Text("Заметки")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .autocapitalization(.sentences)
                }
                
                Section(header: Text("Теги")) {
                    ScrollView {
                        FlowLayout(spacing: 8) {
                            ForEach(Array(Tags.allTags), id: \.self) { tag in
                                TagButton(
                                    title: tag,
                                    isSelected: selectedTags.contains(tag),
                                    action: { toggleTag(tag) },
                                    isGuestTag: false
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .frame(minHeight: 100)
                }
                
                Section(header: Text("Гости")) {
                    ScrollView {
                        FlowLayout(spacing: 8) {
                            ForEach(Array(GuestTags.allTags), id: \.self) { tag in
                                TagButton(
                                    title: tag,
                                    isSelected: selectedGuestTags.contains(tag),
                                    action: { toggleGuestTag(tag) },
                                    isGuestTag: true
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .frame(minHeight: 100)
                }
            }
            .navigationTitle(mix == nil ? "Новый микс" : "Редактирование микса")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(colors.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        validateAndSave()
                    }
                    .disabled(name.isEmpty || composition.isEmpty)
                    .foregroundColor(colors.red)
                }
            }
            .alert("Ошибка", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
            }
            .onAppear {
                if let mix = mix, let currentMix = viewModel.getMixById(mix.id) {
                    name = currentMix.name
                    composition = currentMix.composition
                    strength = Double(currentMix.strength)
                    notes = currentMix.notes
                    selectedTags = Set(currentMix.tags)
                    selectedGuestTags = Set(currentMix.guestTags)
                }
            }
        }
        .accentColor(colors.red)
    }
    
    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    private func toggleGuestTag(_ tag: String) {
        if selectedGuestTags.contains(tag) {
            selectedGuestTags.remove(tag)
        } else {
            selectedGuestTags.insert(tag)
        }
    }
    
    private func validateAndSave() {
        if name.isEmpty {
            alertMessage = "Пожалуйста, введите название микса"
            showingAlert = true
            return
        }
        
        if composition.isEmpty {
            alertMessage = "Пожалуйста, введите состав микса"
            showingAlert = true
            return
        }
        
        let newMix = Mix(
            id: mix?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            composition: composition.trimmingCharacters(in: .whitespacesAndNewlines),
            strength: Int(strength),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            tags: Array(selectedTags),
            guestTags: Array(selectedGuestTags),
            isInDevelopment: mix?.isInDevelopment ?? true
        )
        
        viewModel.saveMix(newMix)
        presentationMode.wrappedValue.dismiss()
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let result = layout(sizes: sizes, proposal: proposal)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let result = layout(sizes: sizes, proposal: proposal)
        
        for (index, subview) in subviews.enumerated() {
            let point = CGPoint(x: result.offsets[index].x + bounds.minX, y: result.offsets[index].y + bounds.minY)
            subview.place(at: point, proposal: .unspecified)
        }
    }
    
    private func layout(sizes: [CGSize], proposal: ProposedViewSize) -> (size: CGSize, offsets: [CGPoint]) {
        var width: CGFloat = 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        var offsets: [CGPoint] = []
        
        for size in sizes {
            if x + size.width > proposal.width ?? .infinity {
                x = 0
                y += maxHeight + spacing
                maxHeight = 0
            }
            
            offsets.append(CGPoint(x: x, y: y))
            
            x += size.width + spacing
            maxHeight = max(maxHeight, size.height)
            width = max(width, x - spacing)
            height = max(height, y + maxHeight)
        }
        
        return (CGSize(width: width, height: height), offsets)
    }
}

struct EditMixView_Previews: PreviewProvider {
    static var previews: some View {
        EditMixView(mix: nil)
            .environmentObject(MixViewModel())
    }
}
