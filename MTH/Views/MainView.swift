import SwiftUI
import Foundation

struct MainView: View {
    @EnvironmentObject var viewModel: MixViewModel
    @State private var showingSettings = false
    @State private var showingAbout = false
    @State private var showingEditMix = false
    @State private var editingMix: Mix?
    
    var body: some View {
        NavigationView {
            TabView {
                MixListView(
                    onAdd: {
                        editingMix = nil
                        showingEditMix = true
                    },
                    onEdit: { mix in
                        // Получаем актуальные данные микса перед открытием редактора
                        if let currentMix = viewModel.getMixById(mix.id) {
                            editingMix = currentMix
                            showingEditMix = true
                        }
                    },
                    onDelete: { mix in
                        viewModel.deleteMix(mix)
                    },
                    onSettings: { showingSettings = true },
                    onAbout: { showingAbout = true },
                    showInDevelopment: false
                )
                .tabItem {
                    Label("Готовые", systemImage: "checkmark.circle")
                }
                
                MixListView(
                    onAdd: {
                        editingMix = nil
                        showingEditMix = true
                    },
                    onEdit: { mix in
                        // Получаем актуальные данные микса перед открытием редактора
                        if let currentMix = viewModel.getMixById(mix.id) {
                            editingMix = currentMix
                            showingEditMix = true
                        }
                    },
                    onDelete: { mix in
                        viewModel.deleteMix(mix)
                    },
                    onSettings: { showingSettings = true },
                    onAbout: { showingAbout = true },
                    showInDevelopment: true
                )
                .tabItem {
                    Label("В разработке", systemImage: "hammer")
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .navigationTitle("Мои миксы")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            editingMix = nil
                            showingEditMix = true
                        }) {
                            Image(systemName: "plus")
                        }
                        
                        Menu {
                            Button(action: { showingSettings = true }) {
                                Label("Настройки", systemImage: "gear")
                            }
                            
                            Button(action: { showingAbout = true }) {
                                Label("О приложении", systemImage: "info.circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditMix) {
            if let mix = editingMix {
                EditMixView(mix: mix)
            } else {
                EditMixView(mix: nil)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
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
            .environmentObject(MixViewModel())
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
