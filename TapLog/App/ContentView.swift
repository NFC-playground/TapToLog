//
//  ContentView.swift
//  TapLog
//
//  Created by Sheena Kaw on 10/19/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager

    // Created here (not in TapLogApp) so it's thrown away on sign-out:
    // ContentView only exists while a user is signed in.
    @StateObject private var activityStore = ActivityStore()

    var body: some View {
        TabView {
            Tab("Home", systemImage: "timer") {
                HomeView()
            }
            Tab("History", systemImage: "clock.arrow.circlepath") {
                HistoryView()
            }
            Tab("NFC Tags", systemImage: "wave.3.right") {
                TagSetupView()
            }
            Tab("Settings", systemImage: "gear") {
                SettingsView()
            }
        }
        // env obj makes store available to everything inside it
        // i.e. the settings and home tab get the same instance - activities array
        .environmentObject(activityStore)
        // Load once for whichever tab opens first; re-runs if the user changes.
        .task(id: authManager.currentUserId) {
            guard let userId = authManager.currentUserId else { return }
            await activityStore.load(userId: userId)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
