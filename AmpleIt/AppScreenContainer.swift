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

            ToolbarItem(placement: .topBarTrailing) {
                Button {} label: {
                    logoLabel
                }
                .disabled(true)
                .opacity(0)
                .accessibilityHidden(true)
            }
            ToolbarItem(placement: .principal) {
                HStack {
                    Spacer()
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .lineLimit(1)
                        .matchedGeometryEffect(id: "appTitle", in: chromeNS)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview("AppScreenContainer") {
    PreviewHarness { ctx in
        AppScreenContainer(
            title: "Preview",
            isSidebarOpen: ctx.isSidebarOpen,
            chromeNS: ctx.chromeNS
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
