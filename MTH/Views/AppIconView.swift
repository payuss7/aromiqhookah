import SwiftUI

struct AppIconView: View {
    var body: some View {
        ZStack {
            // Фон
            Color(hex: "01081B")
            
            // Основной круг
            Circle()
                .fill(Color(hex: "FE0000"))
                .frame(width: 200, height: 200)
            
            // Буква M
            Text("M")
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            // Круглый бордер
            Circle()
                .stroke(Color.white, lineWidth: 8)
                .frame(width: 200, height: 200)
        }
        .frame(width: 1024, height: 1024)
    }
}

struct AppIconView_Previews: PreviewProvider {
    static var previews: some View {
        AppIconView()
    }
} 