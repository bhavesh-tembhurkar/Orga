import SwiftUI
import KeychainAccess
import CryptoKit

// The one-time view for setting the user's master password.
struct PasswordSetupView: View {
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    // Controls the navigation flow in `RootView`.
    @Binding var isSetupComplete: Bool

    var body: some View {
        VStack(spacing: 20) {
            Label("Set Your Master Password", systemImage: "key.fill")
                .font(.title)
                .foregroundStyle(Color.brandPrimary)

            SecureField("Enter Password", text: $password)
                .textFieldStyle(.roundedBorder)
            
            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(.roundedBorder)

            Spacer()

            Button("Create Vault", action: savePasswordWithHash)
                .buttonStyle(GlowingButtonStyle())
        }
        .padding(40)
        .frame(width: 400, height: 250)
        .alert("Error", isPresented: $showAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
    }
    
    // Validates and saves a salted hash of the password to the keychain.
    private func savePasswordWithHash() {
        // 1. Validation: Check for empty fields.
        guard !password.isEmpty, !confirmPassword.isEmpty else {
            alertMessage = "Fields cannot be empty."
            showAlert = true
            return
        }
        
        // 2. Validation: Check for matching passwords.
        guard password == confirmPassword else {
            alertMessage = "Passwords do not match."
            showAlert = true
            return
        }
        
        guard let passwordData = password.data(using: .utf8) else {
            alertMessage = "Could not process password."
            showAlert = true
            return
        }
        
        // 3. Create a new, random 256-bit salt.
        let salt = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
        // 4. Combine the salt and password.
        let dataToHash = salt + passwordData
        // 5. Hash the combined data.
        let passwordHash = SHA512.hash(data: dataToHash)
        
        // 6. Save both the hash and the salt to the keychain.
        let keychain = Keychain(service: "com.securbe.Orga")
        do {
            try keychain.set(Data(passwordHash), key: "masterPasswordHash")
            try keychain.set(salt, key: "masterPasswordSalt")
            // Signal to `RootView` to proceed to the next step.
            isSetupComplete = true
        } catch {
            alertMessage = "Could not save password credentials."
            showAlert = true
        }
    }
}
