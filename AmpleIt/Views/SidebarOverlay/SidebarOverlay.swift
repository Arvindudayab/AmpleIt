import SwiftUI

struct SidebarOverlay: View {
    @Binding var isOpen: Bool
    @Binding var selectedTab: AppTab
    let chromeNS: Namespace.ID

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                if isOpen {
                    Rectangle()
                        .fill(Color("AppBackground").opacity(0.1))
                        .ignoresSafeArea()
                        .background(.ultraThinMaterial)
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                isOpen = false
                            }
                        }
                }

                SidebarCard(
                    isOpen: $isOpen,
                    selectedTab: $selectedTab,
                    containerSize: geo.size,
                    chromeNS: chromeNS
                )
                .padding(.leading, 14)
                .padding(.top, geo.safeAreaInsets.top + 8)
            }
        }
        .allowsHitTesting(isOpen)
        .animation(.spring(response: 0.42, dampingFraction: 0.88), value: isOpen)
    }
}

#Preview("Sidebar – Open") {
    SidebarPreviewWrapper(isOpen: true)
}

private struct SidebarPreviewWrapper: View {
    @State var isOpen: Bool
    @State private var selectedTab: AppTab = .songs
    @Namespace private var chromeNS

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.25),
                    Color.black.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("Underlying App Content")
                    .font(.title2.weight(.semibold))
                Text("Tap outside the sidebar to dismiss")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()

            SidebarOverlay(
                isOpen: $isOpen,
                selectedTab: $selectedTab,
                chromeNS: chromeNS
            )
        }
    }
}
