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
    @AppStorage("currentUserID") private var currentUserID: String = ""
    
    @State private var showingClearConfirmation = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Current User") {
                    Picker("Logged in as", selection: $currentUserID) {
                        Text("None").tag("")
                        ForEach(users) { user in
                            Text(user.name).tag(user.id.uuidString)
                        }
                    }
                }
                Section("Data Overview") {
                    HStack {
                        Text("Users")
                        Spacer()
                        Text("\(users.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Activities")
                        Spacer()
                        Text("\(activities.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("NFC Tags")
                        Spacer()
                        Text("\(nfcTags.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Tracking Sessions")
                        Spacer()
                        Text("\(sessions.count)")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Development Tools") {
                    Button {
                        Task { @MainActor in
                            SeedData.generateSeedData(modelContext: modelContext)
                        }
                    } label: {
                        Label("Generate Seed Data", systemImage: "cylinder.fill")
                    }
                    
                    Button(role: .destructive) {
                        showingClearConfirmation = true
                    } label: {
                        Label("Clear All Data", systemImage: "trash.fill")
                    }
                }
            }
            .navigationTitle("Settings")
            // if the saved ID doesn’t match existing user, reset to None
            .onAppear {
                if !users.contains(where: { $0.id.uuidString == currentUserID }) {
                    currentUserID = ""
                }
            }
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
}
