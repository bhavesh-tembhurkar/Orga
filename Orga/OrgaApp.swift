import SwiftUI
import KeychainAccess

// The main entry point for the application.
@main
struct OrgaApp: App {
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// A private router view to manage the app's initial state.
private struct RootView: View {
    
    // True if a master password hash exists in the keychain.
    @State private var hasMasterPassword: Bool
    // True if the user has chosen a security level.
    @State private var hasCompletedSecuritySetup: Bool
    // Controls the presentation of the main `ContentView`.
    @State private var isUnlocked = false

    // Checks keychain and settings to determine the initial app state.
    init() {
        let keychain = Keychain(service: "com.securbe.Orga")
        
        if (try? keychain.getData("masterPasswordHash")) != nil {
            _hasMasterPassword = State(initialValue: true)
        } else {
            _hasMasterPassword = State(initialValue: false)
        }
        
        _hasCompletedSecuritySetup = State(initialValue: SettingsManager.shared.hasCompletedSecuritySetup())
    }

    var body: some View {
        // Main navigation logic for the app.
        // 1. If no password, force setup.
        if !hasMasterPassword {
            PasswordSetupView(isSetupComplete: $hasMasterPassword)
        // 2. If no security setting, force setup.
        } else if !hasCompletedSecuritySetup {
            SecuritySetupView(isFullySetup: $hasCompletedSecuritySetup)
        // 3. If locked, show login screen.
        } else if !isUnlocked {
            LoginView(isUnlocked: $isUnlocked)
        // 4. If all checks pass, show the main app.
        } else {
            ContentView()
        }
    }
}
