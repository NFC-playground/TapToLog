//
//  SettingsView.swift
//  TapLog
//
//  Created by Sheena Kaw on 10/22/26.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @Query private var activities: [Activity]
    @Query private var nfcTags: [NFCTag]
    @Query private var sessions: [TrackingSession]
    @EnvironmentObject var authManager: AuthManager
    
    @State private var showingClearConfirmation = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    LabeledContent("Signed in as", value: authManager.currentUserEmail ?? "—")
                    Button("Sign Out", role: .destructive) {
                        Task { try? await authManager.signOut() }
                    }
                }
                
            }
            .navigationTitle("Settings")
            .alert("Clear All Data?", isPresented: $showingClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    Task { @MainActor in
                        SeedData.clearAllData(modelContext: modelContext)
                    }
                }
            } message: {
                Text("This will delete all users, activities, tags, and tracking sessions. This action cannot be undone.")
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(SeedData.previewContainer)
        .environmentObject(AuthManager())
}
