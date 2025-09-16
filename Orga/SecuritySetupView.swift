import SwiftUI

// The one-time view for choosing the app's security level.
struct SecuritySetupView: View {
    
    // Controls the navigation flow in `RootView`.
    @Binding var isFullySetup: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("O")
                .font(.system(size: 60, weight: .bold))
                .padding(20)
                .background(Color.brandPrimary)
                .foregroundStyle(.white)
                .clipShape(Circle())
            
            Text("Choose Your Security Level")
                .font(.title)
            
            Text("This choice can be changed later in the app's toolbar.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 10)

            // Option 1: Advanced Security (AES-256 Encryption)
            VStack(alignment: .leading) {
                Text("Advanced Security")
                    .font(.headline)
                Text("Encrypts files with strong AES-256. This is the most secure option, but uses more temporary RAM for large files.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 10)
                
                Button("Select Advanced Security") {
                    // Save the 'Advanced' choice and proceed.
                    SettingsManager.shared.save(securityLevel: .advanced)
                    isFullySetup = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
            
            // Option 2: Fast Hide (Rename, Less Secure)
            VStack(alignment: .leading) {
                Text("Fast Hide (Less Secure)")
                    .font(.headline)
                Text("Instantly hides files by renaming them. This is very fast and uses no extra memory, but it does not encrypt the data.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 10)

                Button("Select Fast Hide") {
                    // Save the 'Fast Hide' choice and proceed.
                    SettingsManager.shared.save(securityLevel: .fastHide)
                    isFullySetup = true
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
        }
        .padding(40)
        .frame(width: 500)
    }
}
