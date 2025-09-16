import Foundation

// Defines the user-selectable security modes.
enum SecurityLevel: String {
    case unknown
    case fastHide
    case advanced
}

// Manages persistent app settings using UserDefaults.
class SettingsManager {
    // Singleton instance for global access.
    static let shared = SettingsManager()
    
    // Interface to the app's persistent settings.
    private let defaults = UserDefaults.standard
    
    // UserDefaults keys.
    private let securityLevelKey = "securityLevelSetting_v2"
    private let setupCompleteKey = "hasCompletedInitialSecuritySetup_v2"

    // Saves the chosen security level and marks setup as complete.
    func save(securityLevel: SecurityLevel) {
        // Don't save the .unknown default state.
        if securityLevel != .unknown {
            defaults.set(securityLevel.rawValue, forKey: securityLevelKey)
            defaults.set(true, forKey: setupCompleteKey)
        }
    }

    // Loads the saved security level from UserDefaults.
    func loadSecurityLevel() -> SecurityLevel {
        guard let savedValue = defaults.string(forKey: securityLevelKey) else {
            return .unknown
        }
        // Default to .unknown if the saved value is invalid.
        return SecurityLevel(rawValue: savedValue) ?? .unknown
    }

    // Checks if the initial security setup has been completed.
    func hasCompletedSecuritySetup() -> Bool {
        return defaults.bool(forKey: setupCompleteKey)
    }
}
