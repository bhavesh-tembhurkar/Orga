import SwiftUI
import KeychainAccess

struct PasswordSetupView: View {
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Binding var isSetupComplete: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Set Your Master Password")
                .font(.title)

            SecureField("Enter Password", text: $password)
            SecureField("Confirm Password", text: $confirmPassword)

            Button("Create Vault") {
                if password.isEmpty || confirmPassword.isEmpty {
                    alertMessage = "Fields cannot be empty."
                    showAlert = true
                } else if password != confirmPassword {
                    alertMessage = "Passwords do not match."
                    showAlert = true
                } else {
                    let keychain = Keychain(service: "com.securbe.Orga")
                    do {
                        try keychain.set(password, key: "masterPassword")
                        isSetupComplete = true
                    } catch {
                        alertMessage = "Could not save password. Please try again."
                        showAlert = true
                    }
                }
            } // End of Button
        } // End of VStack
        .padding()
        .frame(width: 300)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    } // End of body
} // End of PasswordSetupView struct

#Preview {
    PasswordSetupView(isSetupComplete: .constant(false))
}
