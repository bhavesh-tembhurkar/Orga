import SwiftUI
import KeychainAccess

// Categories for the sidebar file filter.
enum FilterCategory: CaseIterable {
    case all, images, videos, documents, music, others
    
    // The user-facing display name.
    var displayName: String {
        switch self {
        case .all: return "All Files"
        case .images: return "Images"
        case .videos: return "Videos"
        case .documents: return "Documents"
        case .music: return "Music"
        case .others: return "Others"
        }
    }
    
    // The SF Symbol icon name.
    var iconName: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .images: return "photo.fill"
        case .videos: return "video.fill"
        case .documents: return "doc.text.fill"
        case .music: return "music.note"
        case .others: return "ellipsis.circle.fill"
        }
    }
}

// Manages all app state, file operations, and crypto.
class ContentViewModel: ObservableObject {
    
    // Manages all encryption and decryption operations.
    private let cryptoManager = CryptoManager()
    
    // The current security mode (fast or advanced).
    private var securityLevel: SecurityLevel = .unknown
    
    // Timer to clean up temp preview files when app is backgrounded.
    private var cleanupTimer: Timer?
    
    // The master list of all items in the vault.
    @Published var vaultedFiles: [VaultItem] = []
    
    // Shows a progress view when true.
    @Published var isProcessing = false
    
    // The status text for the progress view (e.g., "Processing 1 of 5...").
    @Published var processingStatusText = ""
    
    // Triggers the "Delete Original(s)?" alert.
    @Published var showSuccessAlert = false
    
    // Triggers the error alert.
    @Published var showErrorAlert = false
    
    // The message to display in the active alert.
    @Published var alertMessage = ""
    
    // Bound to the 'Advanced Security' toggle in the toolbar.
    @Published var isAdvancedSecurityEnabled: Bool {
        didSet {
            // Persist the new security level when toggled.
            let newLevel: SecurityLevel = isAdvancedSecurityEnabled ? .advanced : .fastHide
            SettingsManager.shared.save(securityLevel: newLevel)
            self.securityLevel = newLevel
        }
    }
    
    // Tracks the user's current filter selection.
    @Published var selectedCategory: FilterCategory = .all
    
    // A computed list of files based on the selected category.
    var filteredFiles: [VaultItem] {
        // Optimization: return all files if 'All' is selected.
        guard selectedCategory != .all else {
            return vaultedFiles
        }
        
        return vaultedFiles.filter { item in
            let fileName = item.originalPath.lastPathComponent.lowercased()
            
            // TODO: Refactor this logic into a shared utility/model.
            switch selectedCategory {
            case .images:
                return [".jpg", ".png", ".jpeg", ".gif"].contains { fileName.hasSuffix($0) }
            case .videos:
                return [".mp4", ".mov", ".m4v", ".mkv"].contains { fileName.hasSuffix($0) }
            case .documents:
                return [".pdf", ".doc", ".docx", ".txt"].contains { fileName.hasSuffix($0) }
            case .music:
                return [".mp3", ".m4a", ".wav"].contains { fileName.hasSuffix($0) }
            case .others:
                let knownExtensions: [String] = [".jpg", ".png", ".jpeg", ".gif", ".mp4", ".mov", ".m4v", ".pdf", ".doc", ".docx", ".txt", ".mp3", ".m4a", ".wav"]
                // 'Others' includes any file not in the other categories.
                return !knownExtensions.contains { fileName.hasSuffix($0) }
            default:
                return false
            }
        }
    }
    
    // Caches the original URLs for the 'Delete Original(s)?' prompt.
    private var lastAddedFilesSourceURLs: [URL] = []
    
    // Loads settings, cleans old files, and loads the vault manifest.
    init() {
        let savedLevel = SettingsManager.shared.loadSecurityLevel()
        self.securityLevel = savedLevel
        self.isAdvancedSecurityEnabled = (savedLevel == .advanced)
        
        cleanupTemporaryFiles()
        loadManifest()
        
        // Set up observers to handle app backgrounding/foregrounding.
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: NSApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: NSApplication.didBecomeActiveNotification, object: nil)
    }

    // Starts a timer to clear temp preview files when app backgrounds.
    @objc private func appWillResignActive() {
        guard let tempDir = getTempDirectory(create: false),
              FileManager.default.fileExists(atPath: tempDir.path) else {
            return
        }
        
        // Start a 5-minute timer to clear temp files.
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: false) { _ in
            self.cleanupTemporaryFiles()
        }
    }
    
    // Cancels the temp file cleanup timer when app returns.
    @objc private func appDidBecomeActive() {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
    }

    // Opens the system file panel to select files to hide.
    func addFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        if panel.runModal() == .OK {
            let urlsToProcess = panel.urls
            self.isProcessing = true
            self.processingStatusText = "Preparing to process..."
            self.lastAddedFilesSourceURLs.removeAll()
            
            // Process all files on a background thread to keep UI responsive.
            DispatchQueue.global(qos: .userInitiated).async {
                var processedCount = 0
                for (index, sourceURL) in urlsToProcess.enumerated() {
                    DispatchQueue.main.async {
                        self.processingStatusText = "Processing file \(index + 1) of \(urlsToProcess.count)..."
                    }
                    
                    // Branch logic based on the user's selected security level.
                    if self.securityLevel == .advanced {
                        if self.processFileAdvanced(at: sourceURL) { processedCount += 1 }
                    } else {
                        if self.processFileFastHide(at: sourceURL) { processedCount += 1 }
                    }
                }
                
                // After processing, update UI on the main thread.
                DispatchQueue.main.async {
                    self.isProcessing = false
                    if processedCount > 0 {
                        self.saveManifest()
                        self.alertMessage = "\(processedCount) item(s) have been successfully hidden."
                        self.showSuccessAlert = true
                    }
                }
            }
        }
    }
    
    // Restores selected files from the vault to their original locations.
    func unhideSelectedItems(selection: Set<UUID>) {
        let itemsToUnhide = vaultedFiles.filter { selection.contains($0.id) }
        itemsToUnhide.forEach { item in
            // Branch logic: 'Fast Hide' (has original name) vs 'Advanced' (nil).
            if let originalFileName = item.originalFileName {
                unhideFastHideItem(item: item, originalFileName: originalFileName)
            } else {
                unhideAdvancedItem(item: item)
            }
        }
        
        vaultedFiles.removeAll { selection.contains($0.id) }
        saveManifest()
    }

    // Permanently deletes selected files from the vault and manifest.
    func deleteSelectedItems(selection: Set<UUID>) {
        guard let vaultURL = getVaultDirectory() else { return }
        let itemsToDelete = vaultedFiles.filter { selection.contains($0.id) }
        
        itemsToDelete.forEach { item in
            // Delete the actual file from disk.
            let fileURL = vaultURL.appendingPathComponent(item.fileName)
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        vaultedFiles.removeAll { selection.contains($0.id) }
        saveManifest()
    }
    
    // Securely opens a file for preview by decrypting/copying to a temp dir.
    func openFile(item: VaultItem) {
        cleanupTemporaryFiles()
        
        if let originalFileName = item.originalFileName {
            openFastHideItem(item: item, originalFileName: originalFileName)
        } else {
            openAdvancedItem(item: item)
        }
    }

    // Deletes the source files after a successful hide operation.
    func deleteOriginalFiles() {
        lastAddedFilesSourceURLs.forEach { url in
            try? FileManager.default.removeItem(at: url)
        }
        lastAddedFilesSourceURLs.removeAll()
    }
    
    // 'Fast Hide': Moves the file into the vault and renames it.
    private func processFileFastHide(at sourceURL: URL) -> Bool {
        guard let destinationDirectory = getVaultDirectory() else { return false }
        let newFileName = UUID().uuidString + ".dat"
        let destinationURL = destinationDirectory.appendingPathComponent(newFileName)
        
        do {
            try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
            
            let newItem = VaultItem(id: UUID(), fileName: newFileName, originalPath: sourceURL, originalFileName: sourceURL.lastPathComponent)
            DispatchQueue.main.async { self.vaultedFiles.append(newItem) }
            lastAddedFilesSourceURLs.append(sourceURL)
            return true
        } catch {
            DispatchQueue.main.async {
                self.alertMessage = "Could not hide file: \(sourceURL.lastPathComponent). It may already exist."
                self.showErrorAlert = true
            }
            return false
        }
    }
    
    // 'Advanced': Reads, encrypts (AES-GCM), and writes file data to the vault.
    private func processFileAdvanced(at sourceURL: URL) -> Bool {
        guard let destinationDirectory = getVaultDirectory() else { return false }
        let destinationURL = destinationDirectory.appendingPathComponent(sourceURL.lastPathComponent + ".enc")
        
        // Prevent overwriting an existing file.
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            DispatchQueue.main.async {
                self.alertMessage = "A file named \(sourceURL.lastPathComponent) already exists in the vault."
                self.showErrorAlert = true
            }
            return false
        }
        
        do {
            let fileData = try Data(contentsOf: sourceURL)
            guard let encryptedData = cryptoManager.encrypt(data: fileData) else {
                print("Encryption failed for \(sourceURL.lastPathComponent)")
                return false
            }
            try encryptedData.write(to: destinationURL, options: .atomic)
            
            // 'originalFileName' is nil, flagging this as an 'Advanced' item.
            let newItem = VaultItem(id: UUID(), fileName: destinationURL.lastPathComponent, originalPath: sourceURL, originalFileName: nil)
            DispatchQueue.main.async { self.vaultedFiles.append(newItem) }
            lastAddedFilesSourceURLs.append(sourceURL)
            return true
        } catch {
            print("Error processing (advanced) file \(sourceURL.lastPathComponent): \(error.localizedDescription)")
            return false
        }
    }
    
    // Restores a 'Fast Hide' item by moving and renaming it.
    private func unhideFastHideItem(item: VaultItem, originalFileName: String) {
        guard let vaultURL = getVaultDirectory() else { return }
        let sourceURL = vaultURL.appendingPathComponent(item.fileName)
        let destinationURL = item.originalPath
        
        try? FileManager.default.moveItem(at: sourceURL, to: destinationURL)
    }
    
    // Restores an 'Advanced' item by decrypting it back to its original path.
    private func unhideAdvancedItem(item: VaultItem) {
        guard let vaultURL = getVaultDirectory() else { return }
        let sourceURL = vaultURL.appendingPathComponent(item.fileName)
        let destinationURL = item.originalPath
        
        do {
            let encryptedData = try Data(contentsOf: sourceURL)
            guard let decryptedData = cryptoManager.decrypt(data: encryptedData) else { return }
            try decryptedData.write(to: destinationURL, options: .atomic)
            
            // Delete the encrypted file from the vault after restoring.
            try FileManager.default.removeItem(at: sourceURL)
        } catch {
            print("Error unhiding (advanced) file \(item.fileName): \(error.localizedDescription)")
        }
    }
    
    // Opens a 'Fast Hide' item by *copying* it to a temp dir.
    private func openFastHideItem(item: VaultItem, originalFileName: String) {
        guard let vaultURL = getVaultDirectory(), let tempDir = getTempDirectory() else { return }
        let sourceURL = vaultURL.appendingPathComponent(item.fileName)
        let tempURL = tempDir.appendingPathComponent(originalFileName)
        
        do {
            if FileManager.default.fileExists(atPath: tempURL.path) {
                try FileManager.default.removeItem(at: tempURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: tempURL)
            NSWorkspace.shared.open(tempURL)
        } catch {
            print("Error opening (fast hide) file \(originalFileName): \(error.localizedDescription)")
        }
    }
    
    // Opens an 'Advanced' item by *decrypting* it to a temp dir.
    private func openAdvancedItem(item: VaultItem) {
        guard let vaultURL = getVaultDirectory(), let tempDir = getTempDirectory() else { return }
        let sourceURL = vaultURL.appendingPathComponent(item.fileName)
        let tempURL = tempDir.appendingPathComponent(item.originalPath.lastPathComponent)

        do {
            if FileManager.default.fileExists(atPath: tempURL.path) {
                try FileManager.default.removeItem(at: tempURL)
            }
            
            let encryptedData = try Data(contentsOf: sourceURL)
            guard let decryptedData = cryptoManager.decrypt(data: encryptedData) else { return }
            try decryptedData.write(to: tempURL, options: .atomic)
            
            NSWorkspace.shared.open(tempURL)
        } catch {
            print("Error opening (advanced) file \(item.fileName): \(error.localizedDescription)")
        }
    }
    
    // Deletes the temporary directory used for file previews.
    private func cleanupTemporaryFiles() {
        guard let tempDir = getTempDirectory(create: false) else { return }
        do {
            try FileManager.default.removeItem(at: tempDir)
            print("Successfully cleaned up temporary files.")
        } catch {
            // This is not a critical error; the folder likely just didn't exist.
        }
    }
    
    // Gets or creates the app's unique temporary preview directory.
    private func getTempDirectory(create: Bool = true) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("com.securbe.Orga-Previews")
        if create && !FileManager.default.fileExists(atPath: tempDir.path) {
            do {
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating temp directory: \(error.localizedDescription)")
                return nil
            }
        }
        return tempDir
    }
    
    // Gets or creates the app's secure vault in Application Support.
    private func getVaultDirectory() -> URL? {
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let vaultURL = appSupportURL?.appendingPathComponent("com.securbe.Orga.Vault")
        
        if let vaultURL = vaultURL {
            try? FileManager.default.createDirectory(at: vaultURL, withIntermediateDirectories: true, attributes: nil)
        }
        return vaultURL
    }
    
    // Gets the URL for the manifest.json database file.
    private func getManifestURL() -> URL? {
        return getVaultDirectory()?.appendingPathComponent("manifest.json")
    }
    
    // Saves the current `vaultedFiles` array to manifest.json.
    private func saveManifest() {
        guard let manifestURL = getManifestURL() else { return }
        do {
            let data = try JSONEncoder().encode(vaultedFiles)
            try data.write(to: manifestURL, options: .atomic)
        } catch {
            print("Error saving manifest: \(error.localizedDescription)")
        }
    }
    
    // Loads the manifest.json into the `vaultedFiles` array on launch.
    private func loadManifest() {
        guard let manifestURL = getManifestURL(), FileManager.default.fileExists(atPath: manifestURL.path) else { return }
        do {
            let data = try Data(contentsOf: manifestURL)
            vaultedFiles = try JSONDecoder().decode([VaultItem].self, from: data)
        } catch {
            print("Error loading manifest: \(error.localizedDescription)")
            // If manifest is corrupt, a backup/recovery strategy might be needed.
        }
    }
}
