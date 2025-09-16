import SwiftUI

struct ContentView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = ContentViewModel()
    @State private var selection = Set<UUID>()
    
    var body: some View {
        ZStack {
            // Background depending on color scheme
            if colorScheme == .dark {
                Image("bgSideBar")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)
                    .blur(radius: 2)
                Color.black.opacity(0.15)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Image("background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)
                    .blur(radius: 2)
                Color.white.opacity(0.15)
                    .edgesIgnoringSafeArea(.all)
            }
            
            // Main app interface
            NavigationSplitView {
                // --- Sidebar ---
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(FilterCategory.allCases, id: \.self) { category in
                        
                        HStack {
                            Label(category.displayName, systemImage: category.iconName)
                                .labelStyle(.titleAndIcon)
                                .padding(.leading, 25)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background {
                            if viewModel.selectedCategory == category {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.25))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            }
                        }
                        .foregroundStyle(viewModel.selectedCategory == category
                                         ? (colorScheme == .dark ? .white : .black)
                                         : .secondary)
                        .contentShape(Rectangle())
                        .onHover { inside in
                            if inside {
                                viewModel.selectedCategory = category
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 10)
                .navigationTitle("My Vault")
                .navigationSplitViewColumnWidth(min: 240, ideal: 260, max: 280)
                
            } detail: {
                if viewModel.isProcessing {
                    processingView
                } else if viewModel.filteredFiles.isEmpty {
                    emptyStateView(for: viewModel.selectedCategory)
                } else {
                    fileListView
                }
            }
        }
        .frame(minWidth: 1050, minHeight: 600)
        .toolbar {
            Spacer()
            Toggle(isOn: $viewModel.isAdvancedSecurityEnabled) {
                Label("Advanced Security", systemImage: "lock.shield")
            }
            .toggleStyle(.switch)
            .tint(.green)
            .help("Enable strong AES-256 encryption.")
            
            Button(action: unhideItems) { Image(systemName: "minus.circle") }
                .help("Unhide Selected Item(s) (Cmd+U)")
                .keyboardShortcut("u", modifiers: .command)
                .disabled(selection.isEmpty)
            Button(role: .destructive, action: deleteItems) { Image(systemName: "trash") }
                .help("Delete Selected Item(s) (Cmd+Delete)")
                .keyboardShortcut(.delete, modifiers: .command)
                .disabled(selection.isEmpty)
            Button(action: addItem) { Image(systemName: "plus") }
                .help("Add New File(s) (Cmd+H)")
                .keyboardShortcut("h", modifiers: .command)
        }
        .alert(viewModel.alertMessage, isPresented: $viewModel.showSuccessAlert) {
            Button("Delete Original(s)", role: .destructive) { viewModel.deleteOriginalFiles() }
            Button("Keep Original(s)", role: .cancel) { }
        } message: { Text("Would you like to delete the original item(s)?") }
        .alert("Error", isPresented: $viewModel.showErrorAlert, presenting: viewModel.alertMessage) { msg in
            Button("OK") {}
        } message: { msg in Text(msg) }
    }
    
    // MARK: - Private Views
    
    private var processingView: some View {
        VStack {
            Text(viewModel.processingStatusText)
                .font(.headline)
                .foregroundStyle(colorScheme == .dark ? .white : .black)
            ProgressView().colorInvert()
        }
        .padding(20)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 15))
        .foregroundStyle(colorScheme == .dark ? .white : .black)
    }
    
    private func emptyStateView(for category: FilterCategory) -> some View {
        VStack {
            Image(systemName: category == .all ? "folder.badge.plus" : "questionmark.folder")
                .font(.system(size: 80))
                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.8))
            
            Text(category == .all ? "Your Vault is Empty" : "No Items Found")
                .font(.title).padding(.top)
                .foregroundStyle(colorScheme == .dark ? .white : .black)
            
            Text(category == .all ? "Click the '+' button to add your first file."
                 : "There are no items in the \"\(category.displayName)\" category.")
                .font(.headline)
                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
        }
    }
    
    private var fileListView: some View {
        List(selection: $selection) {
            ForEach(viewModel.filteredFiles) { item in
                HStack {
                    fileTypeIcon(for: item)
                        .font(.title2)
                        .foregroundStyle(Color.brandPrimary)
                        .frame(width: 30)
                    Text(item.originalFileName ?? item.fileName)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                }
                .padding(.vertical, 8)
                .tag(item.id)
                .background(
                    Group {
                        if selection.contains(item.id) {
                            // Custom selection background
                            (colorScheme == .dark
                             ? Color.gray.opacity(0.3)
                             : Color.gray.opacity(0.25))
                            .cornerRadius(6)
                        } else {
                            Color.clear
                        }
                    }
                )
                // --- Hover effect like sidebar ---
                .contentShape(Rectangle())
                .onHover { inside in
                    if inside {
                        selection = [item.id] // auto-select hovered item
                    }
                }
                .contextMenu {
                    Button("Open") { viewModel.openFile(item: item) }
                }
            }
        }
        .scrollContentBackground(.hidden) // removes system background
        .listStyle(.plain) 
    }

    
    private func fileTypeIcon(for item: VaultItem) -> Image {
        let fileName = item.originalPath.lastPathComponent.lowercased()
        if [".jpg", ".png", ".jpeg"].contains(where: fileName.hasSuffix) { return Image(systemName: "photo") }
        if [".mp4", ".mov"].contains(where: fileName.hasSuffix) { return Image(systemName: "video") }
        if fileName.hasSuffix(".pdf") { return Image(systemName: "doc.text") }
        if [".zip", ".rar"].contains(where: fileName.hasSuffix) { return Image(systemName: "archivebox") }
        return Image(systemName: "doc")
    }
    
    private func unhideItems() {
        viewModel.unhideSelectedItems(selection: selection)
        selection.removeAll()
    }
    
    private func deleteItems() {
        viewModel.deleteSelectedItems(selection: selection)
        selection.removeAll()
    }
    
    private func addItem() {
        viewModel.addFile()
    }
}

#Preview {
    ContentView()
}

