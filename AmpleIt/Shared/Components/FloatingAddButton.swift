import SwiftUI

struct FloatingAddButton: View {
    var systemImage: String = "plus"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color("AppBackground"),
                                Color.gray.opacity(0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)
                    .overlay(Circle().strokeBorder(.white.opacity(0.22), lineWidth: 1))
                    .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 8)

                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.primary)
            }
        }
        .accessibilityLabel("Add")
    }
}
