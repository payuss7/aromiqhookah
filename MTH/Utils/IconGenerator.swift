import SwiftUI

class IconGenerator {
    static func generateIcon() {
        let iconView = AppIconView()
        let renderer = ImageRenderer(content: iconView)
        
        // Устанавливаем размер 1024x1024
        renderer.proposedSize = ProposedViewSize(width: 1024, height: 1024)
        
        // Получаем изображение
        if let image = renderer.uiImage {
            // Сохраняем в файл
            if let data = image.pngData() {
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileURL = documentsDirectory.appendingPathComponent("app_icon.png")
                try? data.write(to: fileURL)
                print("Иконка сохранена в: \(fileURL.path)")
            }
        }
    }
} 