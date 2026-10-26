//
//  HistoryView.swift
//  TapLog
//
//  Created by Elissa Alarmani on 10/21/26.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    
    @Environment(\.modelContext) private var modelContext
    // All sessions, newest first
    @Query(sort: \TrackingSession.date, order: .reverse)
    private var sessions: [TrackingSession]
    
    // Same saved value HomeView and SettingsView use
    @AppStorage("currentUserID") private var currentUserID: String = ""
    
    // Only the logged-in user's sessions
    private var mySessions: [TrackingSession] {
        sessions.filter { $0.user?.id.uuidString == currentUserID }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if currentUserID.isEmpty {
                    ContentUnavailableView(
                        "No user selected",
                        systemImage: "person.crop.circle.badge.questionmark",
                        description: Text("Choose a user in Settings.")
                    )
                } else if mySessions.isEmpty {
                    ContentUnavailableView(
                        "No sessions yet",
                        systemImage: "clock",
                        description: Text("Start a timer on the Home tab.")
                    )
                } else {
                    List(mySessions) { session in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.activity?.name ?? "Unknown activity")
                                .font(.headline)
                            Text(session.date, format: .dateTime.month().day().hour().minute())
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(Duration.seconds(session.duration),
                                 format: .time(pattern: .hourMinuteSecond))
                            .monospacedDigit()
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                modelContext.delete(session)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(SeedData.previewContainer)
}
