//
//  HistoryView.swift
//  TapLog
//
//  Created by Elissa Alarmani on 10/21/26.
//

import SwiftUI

struct HistoryView: View {
    
    // MARK: - Supabase Service & Auth
    @StateObject private var sessionService = TrackingSessionService()
    @EnvironmentObject var authManager: AuthManager
    
    // MARK: - State
    @State private var sessions: [TrackingSessionDTO] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Group {
                if authManager.currentUserId == nil {
                    ContentUnavailableView(
                        "No user logged in",
                        systemImage: "person.crop.circle.badge.questionmark",
                        description: Text("Please log in to view your sessions.")
                    )
                } else if isLoading {
                    ProgressView("Loading sessions...")
                } else if let errorMessage = errorMessage {
                    ContentUnavailableView(
                        "Error Loading Sessions",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                } else if sessions.isEmpty {
                    ContentUnavailableView(
                        "No sessions yet",
                        systemImage: "clock",
                        description: Text("Start a timer on the Home tab.")
                    )
                } else {
                    List(sessions) { session in
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
                                Task {
                                    await deleteSession(session)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .refreshable {
                        await loadSessions()
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            try? await authManager.signOut()
                        }
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .task {
                await loadSessions()
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadSessions() async {
        guard let userId = authManager.currentUserId else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            sessions = try await sessionService.fetchSessions(forUserId: userId)
        } catch {
            errorMessage = "Failed to load sessions: \(error.localizedDescription)"
            print("❌ Error loading sessions: \(error)")
        }
        
        isLoading = false
    }
    
    private func deleteSession(_ session: TrackingSessionDTO) async {
        do {
            try await sessionService.deleteSession(id: session.id)
            // Remove from local array for immediate UI update
            sessions.removeAll { $0.id == session.id }
        } catch {
            errorMessage = "Failed to delete session: \(error.localizedDescription)"
            print("❌ Error deleting session: \(error)")
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(AuthManager())
}
