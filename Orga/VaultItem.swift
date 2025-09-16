import Foundation

// This is the data model for every item stored in the vault.
// It conforms to Codable so we can save it as JSON, and Identifiable so SwiftUI can use it in lists.
struct VaultItem: Codable, Identifiable {
    
    // A unique ID for each item, required by Identifiable.
    let id: UUID
    
    // This stores the name of the file as it exists inside the vault.
    // For "Advanced Security", this will be "MyPhoto.jpg.enc".
    // For "Fast Hide", this will be a random name like "A4E8-....-9C2.dat".
    let fileName: String
    
    // This stores the original file path on the user's computer, so we know where to "unhide" it to.
    let originalPath: URL
    
    // This new property is crucial for your dual-mode system.
    // For "Advanced Security" files, this will be nil (empty).
    // For "Fast Hide" files, this stores the original friendly name, like "My Holiday Photo.jpg".
    // This is how the app knows what to display in the list and what to rename the file back to.
    let originalFileName: String?
}


