import SwiftUI

struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: MixViewModel
    @StateObject private var profileViewModel = ProfileViewModel()
    
    @State private var selectedTags: Set<String>
    @State private var selectedGuestTags: Set<String>
    @State private var minStrength: Double
    @State private var maxStrength: Double
    @State private var newTag: String = ""
    @State private var newGuestTag: String = ""
    
    init(selectedTags: Set<String>, minStrength: Double, maxStrength: Double) {
        _selectedTags = State(initialValue: selectedTags)
        _selectedGuestTags = State(initialValue: Set<String>())
        _minStrength = State(initialValue: minStrength)
        _maxStrength = State(initialValue: maxStrength)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Крепость")) {
                    VStack {
                        HStack {
                            Text("От: \(Int(minStrength))%")
                            Spacer()
                            Text("До: \(Int(maxStrength))%")
                        }
                        .font(.caption)
                        
                        RangeSlider(value: $minStrength, in: 0...100, step: 1)
                        RangeSlider(value: $maxStrength, in: 0...100, step: 1)
                    }
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
                    
                    ForEach(Array(selectedTags), id: \.self) { tag in
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
                    
                    ForEach(Array(selectedGuestTags), id: \.self) { tag in
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
            .navigationTitle("Фильтры")
            .navigationBarItems(
                leading: Button("Сбросить") {
                    resetFilters()
                },
                trailing: Button("Применить") {
                    applyFilters()
                }
            )
        }
    }
    
    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tag.isEmpty {
            selectedTags.insert(tag)
            newTag = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        selectedTags.remove(tag)
    }
    
    private func addGuestTag() {
        let tag = newGuestTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tag.isEmpty {
            selectedGuestTags.insert(tag)
            newGuestTag = ""
        }
    }
    
    private func removeGuestTag(_ tag: String) {
        selectedGuestTags.remove(tag)
    }
    
    private func resetFilters() {
        selectedTags.removeAll()
        selectedGuestTags.removeAll()
        minStrength = 0
        maxStrength = 100
    }
    
    private func applyFilters() {
        viewModel.selectedTags = selectedTags
        viewModel.selectedGuestTags = selectedGuestTags
        viewModel.minStrength = Int(minStrength)
        viewModel.maxStrength = Int(maxStrength)
        dismiss()
    }
}

struct RangeSlider: View {
    @Binding var value: Double
    let bounds: ClosedRange<Double>
    let step: Double
    
    init(value: Binding<Double>, in bounds: ClosedRange<Double>, step: Double = 1) {
        self._value = value
        self.bounds = bounds
        self.step = step
    }
    
    var body: some View {
        Slider(value: $value, in: bounds, step: step)
    }
}

struct FilterView_Previews: PreviewProvider {
    static var previews: some View {
        FilterView(selectedTags: ["Тег 1", "Тег 2"], minStrength: 0, maxStrength: 100)
            .environmentObject(MixViewModel())
    }
} 