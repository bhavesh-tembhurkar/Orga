import SwiftUI

struct ContentView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = ContentViewModel()
    @State private var selection = Set<UUID>()
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            if viewModel.vaultedFiles.isEmpty {
                emptyStateView
            } else {
                fileListView
            }
        } // End of VStack
        .toolbar {
            Button(action: unhideItems) {
                Image(systemName: "minus.circle")
            }
            .disabled(selection.isEmpty)

            Button(role: .destructive, action: deleteItems) {
                Image(systemName: "trash")
            }
            .disabled(selection.isEmpty)

            Button(action: addItem) {
                Image(systemName: "plus")
            }
        } // End of .toolbar
        .alert(
            viewModel.alertMessage,
            isPresented: $viewModel.showSuccessAlert
        ) {
            Button("Delete Original(s)", role: .destructive) {
                viewModel.deleteOriginalFiles()
            }
            Button("Keep Original(s)", role: .cancel) { }
        } message: {
            Text("Would you like to delete the original item(s)?")
        }
    } // End of body
    
    // MARK: - Private Views
    
    private var emptyStateView: some View {
        
        VStack {
            Spacer()
            Text("Your Vault is Empty")
                .font(.title)
            Text("Click the '+' button to add your first file.")
                .foregroundStyle(.secondary)
            Spacer()
        } // End of VStack
    } // End of emptyStateView
    
    private var fileListView: some View {
        List(selection: $selection) {
            ForEach(viewModel.vaultedFiles) { item in
                Text(item.fileName).tag(item.id)
            }
        } // End of List
    } // End of fileListView
    
    // MARK: - Private Methods
    
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
    
} // End of ContentView struct

#Preview {
    ContentView()
}
