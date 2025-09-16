import Foundation
import KeychainAccess
import CryptoKit
import LocalAuthentication

class LoginViewModel: ObservableObject {
    
    func authenticateWithBiometrics(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Log in to your vault with Touch ID."
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        } else {
            // This Mac does not have Touch ID or it's not set up.
            completion(false)
        }
    }
    
    // This is the secure hash verification logic.
    func checkPassword(password: String) -> Bool {
        let keychain = Keychain(service: "com.securbe.Orga")
        
        // 1. Get the stored HASH and SALT from the Keychain.
        guard let storedHashData = try? keychain.getData("masterPasswordHash"),
              let salt = try? keychain.getData("masterPasswordSalt") else {
            print("Password hash or salt not found in keychain.")
            return false
        }
        
        // 2. Convert the password the user just typed into Data.
        guard let passwordData = password.data(using: .utf8) else {
            return false
        }
        
        // 3. Combine the user's typed password with the STORED salt.
        let dataToHash = salt + passwordData
        
        // 4. Calculate a NEW hash from the combined data.
        let newHash = SHA512.hash(data: dataToHash)
        
        // 5. Compare the NEW hash to the STORED hash.
        // If they match, the password is correct!
        return Data(newHash) == storedHashData
    }
}


