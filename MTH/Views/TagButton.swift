import SwiftUI

struct TagButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    let isGuestTag: Bool
    @Environment(\.colorScheme) var colorScheme
    
    // Цветовая схема
    private let colors = (
        red: Color(hex: "FF0000"),
        orange: Color(hex: "FFA500"),
        darkBlue: Color(hex: "01081B")
    )
    
    init(title: String, isSelected: Bool, action: @escaping () -> Void, isGuestTag: Bool = false) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
        self.isGuestTag = isGuestTag
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    isSelected 
                    ? (isGuestTag ? colors.red.opacity(0.3) : colors.orange.opacity(0.3))
                    : Color.gray.opacity(0.1)
                )
                .foregroundColor(
                    isSelected 
                    ? (isGuestTag ? colors.red : colors.orange)
                    : (colorScheme == .dark ? .white : .gray)
                )
                .cornerRadius(8)
        }
    }
} 