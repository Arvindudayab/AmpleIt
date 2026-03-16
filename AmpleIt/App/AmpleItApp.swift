//
//  AmpleItApp.swift
//  AmpleIt
//
//  Created by Arvind Udayabanu on 12/17/25.
//

import SwiftUI

@main
struct AmpleItApp: App {
    @StateObject private var libraryStore = LibraryStore()
    @StateObject private var audioPlayer = AudioPlayerService()
    @State private var isLoading = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isLoading {
                    LoadingView()
                        .transition(.opacity)
                } else {
                    RootTabView()
                        .environmentObject(libraryStore)
                        .environmentObject(audioPlayer)
                        .transition(.opacity)
                }
            }
            .task {
                guard isLoading else { return }
                try? await Task.sleep(for: .milliseconds(1400))
                withAnimation(.easeOut(duration: 0.28)) {
                    isLoading = false
                }
            }
        }
    }
}
