import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingAddProfile = false
    @State private var newProfileName = ""
    @Environment(\.colorScheme) var colorScheme
    
    // Цветовая схема
    private let colors = (
        red: Color(hex: "FF0000"),
        orange: Color(hex: "FFA500"),
        darkBlue: Color(hex: "01081B")
    )
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.profiles) { profile in
                    ProfileRow(profile: profile, isActive: profile.id == viewModel.activeProfile?.id)
                        .onTapGesture {
                            viewModel.setActiveProfile(profile)
                        }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.deleteProfile(viewModel.profiles[index])
                    }
                }
            }
            .navigationTitle("Профили")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddProfile = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Новый профиль", isPresented: $showingAddProfile) {
                TextField("Имя профиля", text: $newProfileName)
                Button("Отмена", role: .cancel) {
                    newProfileName = ""
                }
                Button("Создать") {
                    if !newProfileName.isEmpty {
                        viewModel.createProfile(name: newProfileName)
                        newProfileName = ""
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .alert("Ошибка", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
        }
    }
}

struct ProfileRow: View {
    let profile: Profile
    let isActive: Bool
    @Environment(\.colorScheme) var colorScheme
    
    private let colors = (
        red: Color(hex: "FF0000"),
        orange: Color(hex: "FFA500"),
        darkBlue: Color(hex: "01081B")
    )
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(profile.name)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : colors.darkBlue)
            }
            
            Spacer()
            
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(colors.red)
            }
        }
        .padding(.vertical, 8)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
} 