//
//  HomeView.swift
//  TapLog
//
//  Created by Elissa Alarmani on 10/21/26.
//
import SwiftData
import SwiftUI

struct HomeView: View {
    // Temporary: replaced by the real active session once SwiftData lands.
    @State private var startedAt: Date? = nil
    
    //use modelContext this to access the database
    @Environment(\.modelContext) private var modelContext
    
    @Query private var users: [User]
    @Query private var activities: [Activity]
    
    @AppStorage("currentUserID") private var currentUserID: String = ""
    
    // computed property User or nil
    private var currentUser: User? {
        //$0 is shorthand for “the user currently being checked
        users.first { $0.id.uuidString == currentUserID }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let startedAt {
                    runningView(startedAt: startedAt)
                } else {
                    idleView
                }
            }
            .navigationTitle("Home")
        }
    }
    
    private var idleView: some View {
        VStack(spacing: 16) {
            Text("No active timer")
                .font(.headline)
            Text("Tap your NFC to start")
                .foregroundStyle(.secondary)
            Button("Start (test)") {
                startedAt = .now
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private func runningView(startedAt: Date) -> some View {
        VStack(spacing: 24) {
            Text("Reading")
                .font(.title2)
            Text(startedAt, style: .timer)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()
            Button("Stop", role: .destructive) {
                stopTimer()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    private func stopTimer() {
        guard let startedAt else { return }
        self.startedAt = nil
        
        guard let currentUser else {
            print("⚠️ No current user selected. Session not saved.")
            return
        }
        
        
        let session = TrackingSession(
            date: startedAt,
            duration: Date.now.timeIntervalSince(startedAt),
            sessionDescription: "",
            user: currentUser,
            activity: activities.first,
            nfcTag: nil
        )
        modelContext.insert(session)
        print("✅ Saved session for \(currentUser.name)")
        
        self.startedAt = nil
    }
}

#Preview {
    HomeView()
        .modelContainer(SeedData.previewContainer)
}
