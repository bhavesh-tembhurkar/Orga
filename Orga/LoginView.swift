import SwiftUI

// The view responsible for password and biometric authentication.
struct LoginView: View {
    // Handles the logic for authentication.
    @StateObject private var viewModel = LoginViewModel()
    @State private var password = ""
    // A binding that controls the app's locked state.
    @Binding var isUnlocked: Bool

    // Triggers the "Login Failed" alert.
    @State private var showAlert = false
    @State private var alertMessage = "Wrong Password. Please try again."

    var body: some View {
        VStack(spacing: 20) {
            Text("O")
                .font(.system(size: 60, weight: .bold))
                .padding(20)
                .background(Color.brandPrimary)
                .foregroundStyle(.white)
                .clipShape(Circle())
            
            Text("Enter Your Password")
                .font(.title2)
                .padding(.top)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                // Allows login by pressing the Return/Enter key.
                .onSubmit(handlePasswordLogin)

            Button("Unlock", action: handlePasswordLogin)
                .buttonStyle(GlowingButtonStyle())
            
            // Biometric (Touch ID) login button.
            Button(action: handleBiometricLogin) {
                Image(systemName: "touchid")
                    .font(.largeTitle)
                    .foregroundStyle(Color.brandSecondary)
            }
            .buttonStyle(.plain)
            .padding(.top)
        }
        .padding(40)
        .frame(width: 400)
        .alert("Login Failed", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        // Attempt biometric login as soon as the view appears.
        .onAppear(perform: handleBiometricLogin)
    }
    
    // Checks the entered password against the stored hash.
    private func handlePasswordLogin() {
        if viewModel.checkPassword(password: password) {
            isUnlocked = true
        } else {
            password = ""
            showAlert = true
        }
    }
    
    // Initiates a biometric authentication request.
    private func handleBiometricLogin() {
        viewModel.authenticateWithBiometrics { success in
            if success {
                isUnlocked = true
            }
        }
    }
}
