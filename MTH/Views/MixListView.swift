import SwiftUI

struct MixRow: View {
    @Environment(\.colorScheme) var colorScheme
    let mix: Mix
    let onDelete: (Mix) -> Void
    let onEdit: (Mix) -> Void
    let onMove: (Mix) -> Void
    @State private var showDetail = false
    @State private var showDeleteAlert = false
    
    // Цветовая схема
    private let colors = (
        red: Color(hex: "FE0000"),
        orange: Color(hex: "F5B769"),
        darkBlue: Color(hex: "01081B")
    )
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mix.name)
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : colors.darkBlue)
                    
                    Text("Крепость: \(mix.strength)/10")
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white : colors.orange)
                }
                
                Spacer()
                
                Button(action: { onMove(mix) }) {
                    Image(systemName: mix.isInDevelopment ? "hammer" : "checkmark.circle")
                        .foregroundColor(mix.isInDevelopment ? colors.orange : .green)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { showDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(colors.red)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Text(mix.composition)
                .font(.subheadline)
                .foregroundColor(colorScheme == .dark ? .white : .secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            
            if !mix.notes.isEmpty {
                Text("Заметки: \(mix.notes)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if !mix.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(mix.tags, id: \.self) { tag in
                            TagButton(
                                title: tag,
                                isSelected: true,
                                action: {},
                                isGuestTag: false
                            )
                        }
                    }
                }
            }
            
            if !mix.guestTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(mix.guestTags, id: \.self) { tag in
                            TagButton(
                                title: tag,
                                isSelected: true,
                                action: {},
                                isGuestTag: true
                            )
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            showDetail = true
        }
        .sheet(isPresented: $showDetail) {
            MixDetailView(mix: mix, onEdit: onEdit)
        }
        .alert("Удалить микс?", isPresented: $showDeleteAlert) {
            Button("Нет", role: .cancel) { }
            Button("Да", role: .destructive) {
                onDelete(mix)
            }
        } message: {
            Text("Вы уверены, что хотите удалить микс \"\(mix.name)\"?")
                .foregroundColor(colorScheme == .dark ? .white : .primary)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("Удалить", systemImage: "trash")
            }
            
            Button {
                onEdit(mix)
            } label: {
                Label("Редактировать", systemImage: "pencil")
            }
            .tint(colors.orange)
        }
    }
}

struct MixListView: View {
    @EnvironmentObject var viewModel: MixViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedMix: Mix? = nil
    @State private var mixToDelete: Mix? = nil
    @State private var showingFilter = false
    let onEdit: (Mix) -> Void
    let onDelete: (Mix) -> Void
    
    // Цветовая схема
    private let colors = (
        red: Color(hex: "FF0000"),
        orange: Color(hex: "FFA500"),
        darkBlue: Color(hex: "01081B")
    )
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                SearchBar(text: $viewModel.searchText)
                    .padding(.horizontal)
                
                Button(action: { showingFilter = true }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(colors.red)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing)
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(colors.red)
                    
                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundColor(colorScheme == .dark ? .white : colors.darkBlue)
                    
                    Button(action: {
                        Task {
                            await viewModel.loadMixes()
                        }
                    }) {
                        Text("Повторить")
                            .foregroundColor(.white)
                            .padding()
                            .background(colors.red)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section(header: Text("Готовые миксы")) {
                        ForEach(viewModel.readyMixes) { mix in
                            MixRow(mix: mix, onDelete: { viewModel.deleteMix($0) }, onEdit: { onEdit($0) }, onMove: { viewModel.moveMix($0) })
                        }
                    }
                    Section(header: Text("В разработке")) {
                        ForEach(viewModel.developmentMixes) { mix in
                            MixRow(mix: mix, onDelete: { viewModel.deleteMix($0) }, onEdit: { onEdit($0) }, onMove: { viewModel.moveMix($0) })
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .refreshable {
                    await viewModel.loadMixes()
                }
            }
        }
        .navigationTitle("Миксы")
        .sheet(isPresented: $showingFilter) {
            FilterView(
                selectedTags: viewModel.selectedTags,
                minStrength: Double(viewModel.minStrength),
                maxStrength: Double(viewModel.maxStrength)
            )
        }
        .sheet(item: $selectedMix) { mix in
            MixDetailView(mix: mix, onEdit: onEdit)
        }
        .alert("", isPresented: Binding(
            get: { mixToDelete != nil },
            set: { if !$0 { mixToDelete = nil } }
        )) {
            Button("Нет", role: .cancel) {
                mixToDelete = nil
            }
            Button("Да", role: .destructive) {
                if let mix = mixToDelete {
                    onDelete(mix)
                    mixToDelete = nil
                }
            }
        } message: {
            if let mix = mixToDelete {
                Text("Вы уверены, что хотите удалить микс \"\(mix.name)\"?")
                    .font(.title3)
                    .fontWeight(.bold)
            }
        }
    }
}

struct MixDetailView: View {
    let mix: Mix
    let onEdit: (Mix) -> Void
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: MixViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var currentMix: Mix
    
    init(mix: Mix, onEdit: @escaping (Mix) -> Void) {
        self.mix = mix
        self.onEdit = onEdit
        _currentMix = State(initialValue: mix)
    }
    
    // Цветовая схема
    private let colors = (
        red: Color(hex: "FF0000"),
        orange: Color(hex: "FFA500"),
        darkBlue: Color(hex: "01081B")
    )
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(currentMix.name)
                        .font(.title)
                        .foregroundColor(colorScheme == .dark ? .white : colors.darkBlue)
                    
                    Text("Крепость: \(currentMix.strength)/10")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : colors.orange)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Состав")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : colors.darkBlue)
                        Text(currentMix.composition)
                            .foregroundColor(colorScheme == .dark ? .white : .secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    if !currentMix.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Заметки")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : colors.darkBlue)
                            Text(currentMix.notes)
                                .foregroundColor(colorScheme == .dark ? .white : .secondary)
                        }
                    }
                    
                    if !currentMix.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Теги")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : colors.darkBlue)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(currentMix.tags, id: \.self) { tag in
                                        TagButton(
                                            title: tag,
                                            isSelected: true,
                                            action: {},
                                            isGuestTag: false
                                        )
                                    }
                                }
                            }
                        }
                    }
                    
                    if !currentMix.guestTags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Гости")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : colors.darkBlue)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(currentMix.guestTags, id: \.self) { tag in
                                        TagButton(
                                            title: tag,
                                            isSelected: true,
                                            action: {},
                                            isGuestTag: true
                                        )
                                    }
                                }
                            }
                        }
                    }
                    
                    HStack(spacing: 16) {
                        Button(action: { shareMix(currentMix) }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Поделиться")
                                    .font(.subheadline)
                            }
                            .foregroundColor(colors.red)
                            .padding()
                            .frame(width: 170)
                            .background(colors.red.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            print("Edit button tapped for mix: \(currentMix.name)")
                            presentationMode.wrappedValue.dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                onEdit(currentMix)
                            }
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Редактировать")
                                    .font(.subheadline)
                            }
                            .foregroundColor(colors.red)
                            .padding()
                            .frame(width: 170)
                            .background(colors.red.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)
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
            .onAppear {
                // Получаем актуальные данные микса при открытии
                if let updatedMix = viewModel.getMixById(mix.id) {
                    currentMix = updatedMix
                }
            }
        }
    }
    
    private func shareMix(_ mix: Mix) {
        let text = viewModel.getMixText(mix)
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        // Закрываем текущий sheet перед показом UIActivityViewController
        presentationMode.wrappedValue.dismiss()
        
        // Небольшая задержка перед показом UIActivityViewController
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        }
    }
}

struct MixListView_Previews: PreviewProvider {
    static var previews: some View {
        MixListView(
            onEdit: { _ in },
            onDelete: { _ in }
        )
        .environmentObject(MixViewModel())
    }
}
