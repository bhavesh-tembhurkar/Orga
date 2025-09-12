import Foundation
import KeychainAccess

class LoginViewModel: ObservableObject {
    
    func checkPassword(password: String) -> Bool {
        
        let keychain = Keychain(service: "com.securbe.Orga")
        let savedPassword = keychain["masterPassword"]
        return password == savedPassword
        
    } // End of checkPassword function
} // End of LoginViewModel class
