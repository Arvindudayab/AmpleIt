//
//  PreviewHelper.swift
//  AmpleIt
//
//  Created by Arvind Udayabanu on 12/19/25.
//

import SwiftUI

/// Shared preview harness for all screens
struct PreviewHarness<Content: View>: View {
    @State var isSidebarOpen: Bool = false
    @State var selectedTab: AppTab = .home
    @State var isPlaying: Bool = true

    @Namespace var chromeNS

    let content: (_ ctx: Context) -> Content

    struct Context {
        let isSidebarOpen: Binding<Bool>
        let selectedTab: Binding<AppTab>
        let isPlaying: Binding<Bool>
        let chromeNS: Namespace.ID
    }

    var body: some View {
        content(
            Context(
                isSidebarOpen: $isSidebarOpen,
                selectedTab: $selectedTab,
                isPlaying: $isPlaying,
                chromeNS: chromeNS
            )
        )
    }
}
