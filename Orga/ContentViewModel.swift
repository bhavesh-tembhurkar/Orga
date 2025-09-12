import SwiftUI

class ContentViewModel: ObservableObject {
    
    private let cryptoManager = CryptoManager()
    
    // MARK: - Published Properties
    
    @Published var vaultedFiles: [VaultItem] = []
    @Published var showSuccessAlert = false
    @Published var alertMessage = ""
    
    
    // MARK: - Properties
    
    var lastAddedFilesSourceURLs: [URL] = []
    
    // MARK: - Initializer
    
    init() {
        loadManifest()
    } // End of init
    
    // MARK: - Public Interface
    
    func addFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = true

        if panel.runModal() == .OK {
            let selectedURLs = panel.urls
            var successfullyCopiedCount = 0
            lastAddedFilesSourceURLs.removeAll()
            
            for sourceURL in selectedURLs {
                guard let destinationDirectory = getVaultDirectory() else { continue }
                let destinationURL = destinationDirectory.appendingPathComponent(sourceURL.lastPathComponent)
                
                print("Attempting to copy '\(sourceURL.lastPathComponent)' to '\(destinationURL.path)'")

                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    print("Skipping \(sourceURL.lastPathComponent) because it already exists.")
                    continue
                }
                
                do {
                    // Step 1: Read the original file's data into memory.
                    let originalData = try Data(contentsOf: sourceURL)
                    
                    // Step 2: Encrypt the data using our CryptoManager.
                    guard let encryptedData = cryptoManager.encrypt(data: originalData) else {
                        print("Encryption failed for \(sourceURL.lastPathComponent)")
                        continue // Skip to the next file if encryption fails
                    }
                    
                    // Step 3: Write the ENCRYPTED data to a new file in the vault.
                    try encryptedData.write(to: destinationURL, options: .atomic)
                    
                    // Baaki ka logic waise hi rahega
                    let newItem = VaultItem(id: UUID(), fileName: sourceURL.lastPathComponent, originalPath: sourceURL)
                    vaultedFiles.append(newItem)
                    
                    successfullyCopiedCount += 1
                    lastAddedFilesSourceURLs.append(sourceURL)
                    
                } catch {
                    print("Error processing file \(sourceURL.lastPathComponent): \(error.localizedDescription)")
                }
            } // End of for loop
            
            if successfullyCopiedCount > 0 {
                saveManifest()
                alertMessage = "\(successfullyCopiedCount) item(s) have been hidden successfully."
                showSuccessAlert = true
            }
        } // End of if panel.runModal
    } // End of addFile
    
    func deleteOriginalFiles() {
        for url in lastAddedFilesSourceURLs {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                print("Error deleting original file \(url.lastPathComponent): \(error.localizedDescription)")
            }
        } // End of for loop
        lastAddedFilesSourceURLs.removeAll()
    } // End of deleteOriginalFiles
    
    func unhideSelectedItems(selection: Set<UUID>) {
        // 1. Find the full VaultItem objects that correspond to the selected IDs.
        let itemsToUnhide = vaultedFiles.filter { selection.contains($0.id) }
        
        guard let vaultURL = getVaultDirectory() else { return }

        // 2. Loop through each item that needs to be unhidden.
        for item in itemsToUnhide {
            let sourceURL = vaultURL.appendingPathComponent(item.fileName)
            // The destination is the original path we saved in our manifest.
            let destinationURL = item.originalPath

            // 3. Check if a file already exists at the original location to avoid errors.
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                print("Cannot unhide \(item.fileName) because an item already exists at the original location.")
                // In a future step, we could ask the user if they want to replace it.
                continue // Skip to the next item in the loop
            }
            
            // 4. Move the file from the vault back to the original location.
            do {
                try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
                print("Successfully unhidden \(item.fileName) to \(destinationURL.path)")
            } catch {
                print("Error unhiding item \(item.fileName): \(error.localizedDescription)")
            }
        }
        
        // 5. After the loop, remove the unhidden items from our array and save the changes.
        vaultedFiles.removeAll { selection.contains($0.id) }
        saveManifest()
        
    } // End of unhideSelectedItems
    
    func deleteSelectedItems(selection: Set<UUID>) {
        guard let vaultURL = getVaultDirectory() else { return }
        
        let itemsToDelete = vaultedFiles.filter { selection.contains($0.id) }
        
        for item in itemsToDelete {
            let fileURL = vaultURL.appendingPathComponent(item.fileName)
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                print("Error deleting item \(item.fileName): \(error.localizedDescription)")
            }
        } // End of for loop
        
        vaultedFiles.removeAll { selection.contains($0.id) }
        saveManifest()
    } // End of deleteSelectedItems

    // MARK: - Private Helper Functions
    
    private func getVaultDirectory() -> URL? {
        guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let vaultURL = appSupportURL.appendingPathComponent("com.securbe.Orga.Vault")
        
        do {
            try FileManager.default.createDirectory(at: vaultURL, withIntermediateDirectories: true, attributes: nil)
            return vaultURL
        } catch {
            print("Error creating vault directory: \(error.localizedDescription)")
            return nil
        }
    } // End of getVaultDirectory
    
    private func getManifestURL() -> URL? {
        guard let vaultURL = getVaultDirectory() else { return nil }
        return vaultURL.appendingPathComponent("manifest.json")
    } // End of getManifestURL
    
    private func saveManifest() {
        guard let manifestURL = getManifestURL() else { return }
        
        do {
            let data = try JSONEncoder().encode(vaultedFiles)
            try data.write(to: manifestURL, options: .atomic)
        } catch {
            print("Error saving manifest: \(error.localizedDescription)")
        }
    } // End of saveManifest
    
    private func loadManifest() {
        guard let manifestURL = getManifestURL(),
              FileManager.default.fileExists(atPath: manifestURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: manifestURL)
            vaultedFiles = try JSONDecoder().decode([VaultItem].self, from: data)
        } catch {
            print("Error loading manifest: \(error.localizedDescription)")
        }
    } // End of loadManifest
    
} // End of ContentViewModel class
