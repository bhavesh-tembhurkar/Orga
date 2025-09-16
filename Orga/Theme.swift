import SwiftUI

// Defines custom brand colors for the app.
extension Color {
    
    // The main brand orange.
    static var brandPrimary: Color {
        return Color(red: 255/255, green: 149/255, blue: 0/255)
    }
    
    // A darker orange for accents.
    static var brandSecondary: Color {
        return Color(red: 230/255, green: 126/255, blue: 0/255)
    }
    
    // A standard gradient using the primary and secondary brand colors.
    static var brandGradient: LinearGradient {
        return LinearGradient(
            gradient: Gradient(colors: [Color.brandPrimary, Color.brandSecondary]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// The app's primary button style with a capsule shape and shadow.
struct GlowingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 30)
            .padding(.vertical, 15)
            .background(Color.brandPrimary)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            // Animate shadow radius when pressed.
            .shadow(color: Color.brandSecondary.opacity(0.6), radius: configuration.isPressed ? 5 : 10, x: 0, y: 5)
            // Animate scale when pressed.
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
