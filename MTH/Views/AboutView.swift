import SwiftUI

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

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
            .environmentObject(MixViewModel())
    }
} 