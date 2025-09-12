import Foundation
import CryptoKit
import KeychainAccess

// Manages all encryption and decryption operations for the app.
class CryptoManager {
    
    private let keychain = Keychain(service: "com.securbe.Orga.EncryptionKey")

    //  Encryption
    

    func encrypt(data: Data) -> Data? {
        guard let key = getKey() else { return nil }
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            print("Error encrypting data: \(error.localizedDescription)")
            return nil
        }
    } // End of encrypt function
    
    //  Decryption
    
    func decrypt(data: Data) -> Data? {
        guard let key = getKey() else { return nil }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return decryptedData
        } catch {
            print("Error decrypting data: \(error.localizedDescription)")
            return nil
        }
    } // End of decrypt function

    //  Key Management
    
    private func getKey() -> SymmetricKey? {
        do {
            if let keyData = try keychain.getData("encryptionKey") {
                return SymmetricKey(data: keyData)
            } else {
                return try generateAndStoreKey()
            }
        } catch {
            print("Error managing key: \(error.localizedDescription)")
            return nil
        }
    } // End of getKey function
    
    private func generateAndStoreKey() throws -> SymmetricKey {
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        try keychain.set(keyData, key: "encryptionKey")
        print("Successfully generated and stored a new encryption key.")
        return newKey
    } // End of generateAndStoreKey function
    
} // End of CryptoManager class
