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

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(libraryStore)
        }
    }
}
