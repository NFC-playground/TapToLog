//
//  TapLogApp.swift
//  TapLog
//
//  Created by Sheena Kaw on 10/19/26.
//

import SwiftUI
import SwiftData

@main
struct TapLogApp: App {
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(authManager)
            } else if authManager.isLoading {
                ProgressView("Checking authentication...")
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
        //creates database that can be access
        // by using: @Environment(\.modelContext)
        .modelContainer(for: [
            User.self,
            Activity.self,
            NFCTag.self,
            NFCTagActivity.self,
            TrackingSession.self
        ])
    }
}
