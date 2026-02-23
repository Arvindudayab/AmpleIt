//
//  AppScreenContainer.swift
//  AmpleIt
//
//  Created by Arvind Udayabanu on 12/18/25.
//

import SwiftUI

struct AppScreenContainer<Content: View>: View {
    let title: String
    @Binding var isSidebarOpen: Bool
    let chromeNS: Namespace.ID
    var wrapInNavigationStack: Bool = true
    var showsSidebarButton: Bool = true
    var showsTrailingPlaceholder: Bool = true
    var trailingToolbar: AnyView? = nil
    @ViewBuilder var content: Content
    
    private var logoLabel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.clear)

            Image("SoundAlphaV1")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.primary)
        }
        .frame(width: 36, height: 36)
    }
    
    var body: some View {
        Group {
            if wrapInNavigationStack {
                NavigationStack {
                    inner
                }
            } else {
                inner
            }
        }
    }

    private var inner: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()
            content
        }
        .toolbar {
            if showsSidebarButton {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isSidebarOpen.toggle()
                        }
                    } label: {
                        logoLabel
                            .matchedGeometryEffect(id: "appLogo", in: chromeNS)
                    }
                }
            }

            if let trailingToolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    trailingToolbar
                }
            } else if showsTrailingPlaceholder {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {} label: {
                        logoLabel
                    }
                    .disabled(true)
                    .opacity(0)
                    .accessibilityHidden(true)
                }
            }
            ToolbarItem(placement: .principal) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                    .matchedGeometryEffect(id: "appTitle", in: chromeNS)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

#Preview("AppScreenContainer") {
    AppScreenContainerPreviewWrapper()
}

private struct AppScreenContainerPreviewWrapper: View {
    @State private var isSidebarOpen: Bool = false
    @Namespace private var chromeNS

    var body: some View {
        AppScreenContainer(
            title: "Preview",
            isSidebarOpen: $isSidebarOpen,
            chromeNS: chromeNS
        ) {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(0..<8) { i in
                        Text("Row \(i + 1)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(
                                .ultraThinMaterial,
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                    }
                }
                .padding()
            }
        }
    }
}
