//
//  SettingsView.swift
//  TapLog
//
//  Created by Sheena Kaw on 10/22/26.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
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
                // list of activities
                Section("Tracking") {
                    NavigationLink {
                        ManageActivitiesView()
                    } label: {
                        Label("Activities", systemImage: "list.bullet")
                    }
                }

            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager())
        .environmentObject(ActivityStore())
}
