import SwiftUI

struct SideMenu: View {
    @Binding var isOpen: Bool
    let onSettings: () -> Void
    let onAbout: () -> Void
    
    // Цветовая схема
    private let colors = (
        red: Color(hex: "FE0000"),
        orange: Color(hex: "F5B769"),
        darkBlue: Color(hex: "01081B")
    )
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Затемнение фона
                if isOpen {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                isOpen = false
                            }
                        }
                }
                
                // Боковое меню
                HStack {
                    VStack(alignment: .leading, spacing: 20) {
                        // Заголовок
                        Text("Меню")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(colors.darkBlue)
                            .padding(.top, 50)
                        
                        // Кнопки меню
                        Button(action: {
                            withAnimation {
                                isOpen = false
                            }
                            onSettings()
                        }) {
                            HStack {
                                Image(systemName: "gear")
                                    .foregroundColor(colors.red)
                                Text("Настройки")
                                    .foregroundColor(colors.darkBlue)
                            }
                            .padding(.vertical, 8)
                        }
                        
                        Button(action: {
                            withAnimation {
                                isOpen = false
                            }
                            onAbout()
                        }) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(colors.red)
                                Text("О приложении")
                                    .foregroundColor(colors.darkBlue)
                            }
                            .padding(.vertical, 8)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .frame(width: geometry.size.width * 0.7)
                    .background(Color.white)
                    .offset(x: isOpen ? 0 : -geometry.size.width)
                    
                    Spacer()
                }
            }
            .animation(.easeInOut, value: isOpen)
        }
    }
} 