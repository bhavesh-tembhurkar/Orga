import Foundation
import CryptoKit
import KeychainAccess

// Handles AES-GCM encryption/decryption and secure key management.
class CryptoManager {
    
    // Interface for the system keychain.
    private let keychain = Keychain(service: "com.securbe.Orga.EncryptionKey")

    // Retrieves the 256-bit AES key from keychain, generating it if needed.
    private func getKey() -> SymmetricKey? {
        do {
            // Use a specific key name to avoid conflicts.
            if let keyData = try keychain.getData("encryptionKey_ck_final") {
                // Key exists, load it.
                return SymmetricKey(data: keyData)
            } else {
                // No key found, generate and store a new one.
                let newKey = SymmetricKey(size: .bits256)
                let keyData = newKey.withUnsafeBytes { Data($0) }
                
                try keychain.set(keyData, key: "encryptionKey_ck_final")
                print("Successfully generated a new CryptoKit 256-bit key.")
                return newKey
            }
        } catch {
            print("Error managing key: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Encrypts data using AES-GCM and returns a combined (nonce + tag + ciphertext) blob.
    func encrypt(data: Data) -> Data? {
        guard let key = getKey() else {
            print("Encryption failed: Could not retrieve key.")
            return nil
        }
        
        do {
            // `seal` performs authenticated encryption (AEAD).
            let sealedBox = try AES.GCM.seal(data, using: key)
            
            // Package nonce, ciphertext, and tag into one Data blob for storage.
            return sealedBox.combined
        } catch {
            print("Error encrypting data: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Decrypts a combined data blob, verifying its integrity.
    func decrypt(data: Data) -> Data? {
        guard let key = getKey() else {
            print("Decryption failed: Could not retrieve key.")
            return nil
        }
        
        do {
            // Recreate the sealed box from the combined data.
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            
            // `open` verifies the auth tag before decrypting. Throws on mismatch.
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return decryptedData
        } catch {
            print("Error decrypting data (key mismatch or data tampered?): \(error.localizedDescription)")
            return nil
        }
    }
}
