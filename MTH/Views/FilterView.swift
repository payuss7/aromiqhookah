import SwiftUI

struct FilterView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: MixViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTags: Set<String>
    @State private var selectedGuestTags: Set<String>
    @State private var minStrength: Double
    @State private var maxStrength: Double
    
    init(selectedTags: Set<String>, minStrength: Double, maxStrength: Double) {
        _selectedTags = State(initialValue: selectedTags)
        _selectedGuestTags = State(initialValue: [])
        _minStrength = State(initialValue: minStrength)
        _maxStrength = State(initialValue: maxStrength)
    }
    
    // Цветовая схема
    private let colors = (
        red: Color(hex: "FE0000"),
        orange: Color(hex: "F5B769"),
        darkBlue: Color(hex: "01081B")
    )
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Крепость")) {
                    VStack(alignment: .leading) {
                        Text("Минимум: \(Int(minStrength))")
                            .foregroundColor(colorScheme == .dark ? .white : colors.darkBlue)
                        Slider(value: $minStrength, in: 1...10, step: 1)
                            .accentColor(colors.red)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Максимум: \(Int(maxStrength))")
                            .foregroundColor(colorScheme == .dark ? .white : colors.darkBlue)
                        Slider(value: $maxStrength, in: 1...10, step: 1)
                            .accentColor(colors.red)
                    }
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
                }
            }
            .navigationTitle("Фильтр")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Сбросить") {
                        resetFilters()
                    }
                    .foregroundColor(colors.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Применить") {
                        applyFilters()
                    }
                    .foregroundColor(colors.red)
                }
            }
        }
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
    
    private func resetFilters() {
        selectedTags.removeAll()
        selectedGuestTags.removeAll()
        minStrength = 1
        maxStrength = 10
    }
    
    private func applyFilters() {
        viewModel.applyFilters(
            selectedTags: selectedTags,
            selectedGuestTags: selectedGuestTags,
            minStrength: Int(minStrength),
            maxStrength: Int(maxStrength)
        )
        presentationMode.wrappedValue.dismiss()
    }
}

struct FilterView_Previews: PreviewProvider {
    static var previews: some View {
        FilterView(selectedTags: [], minStrength: 1, maxStrength: 10)
            .environmentObject(MixViewModel())
    }
} 