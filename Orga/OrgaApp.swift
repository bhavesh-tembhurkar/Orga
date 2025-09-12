import SwiftUI
import KeychainAccess

@main
struct OrgaApp: App {
    @State private var isSetupComplete: Bool
    @State private var isUnlocked = false

    // Check Keychain on launch to decide the initial view.
    init() {
        let keychain = Keychain(service: "com.securbe.Orga")
        if keychain["masterPassword"] != nil {
            _isSetupComplete = State(initialValue: true)
        } else {
            _isSetupComplete = State(initialValue: false)
        }
    } // End of init

    var body: some Scene {
        WindowGroup {
            if isSetupComplete {
                if isUnlocked {
                    ContentView()
                } else {
                    LoginView(isUnlocked: $isUnlocked)
                }
            } else {
                PasswordSetupView(isSetupComplete: $isSetupComplete)
            }
        } // End of WindowGroup
    } // End of body
} // End of OrgaApp struct
