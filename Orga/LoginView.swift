import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var password = ""
    @Binding var isUnlocked: Bool

    @State private var showAlert = false
    @State private var alertMessage = "Wrong Password. Please try again."

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Your Password")
                .font(.title)

            SecureField("Password", text: $password)

            Button("Unlock") {
                let success = viewModel.checkPassword(password: password)
                if success {
                    isUnlocked = true
                } else {
                    showAlert = true
                }
            } // End of Button
        } // End of VStack
        .padding()
        .frame(width: 300)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Login Failed"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    } // End of body
} // End of LoginView struct

#Preview {
    LoginView(isUnlocked: .constant(false))
}
