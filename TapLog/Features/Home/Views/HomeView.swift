//
//  HomeView.swift
//  TapLog
//
//  Created by Elissa Alarmani on 10/21/26.
//
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var activityStore: ActivityStore
    @StateObject private var sessionService = TrackingSessionService()

    @State private var selectedActivityId: UUID?
    @State private var startedAt: Date?
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var selectedActivity: ActivityDTO? {
        activityStore.activities.first { $0.id == selectedActivityId }
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
            // Runs on first appear and whenever the list changes (added in Settings,
            // finished loading, etc.) so the picker always points at a real activity.
            .onChange(of: activityStore.activities, initial: true) {
                ensureValidSelection()
            }
            .alert("Couldn't Save Session", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // when there is no active timer running
    private var idleView: some View {
            VStack(spacing: 16) {
                Text("No active timer")
                    .font(.headline)
                Text("Tap your NFC to start")
                    .foregroundStyle(.secondary)
                
                if activityStore.activities.isEmpty {
                    Text("Add an activity in Settings → Activities to start tracking.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else {
                    Picker("Activity", selection: $selectedActivityId) {
                        ForEach(activityStore.activities) { activity in
                            Text(activity.name).tag(UUID?.some(activity.id))
                        }
                    }
                }
                Button("Start") {
                    startedAt = .now
                }
                .buttonStyle(.borderedProminent, )
                .disabled(isSaving || selectedActivityId == nil)
            }
        }
            
    // 
    private func runningView(startedAt: Date) -> some View {
        VStack(spacing: 24) {
            Text(selectedActivity?.name ?? "No activity")
                .font(.title2)
            Text(startedAt, style: .timer)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()
            Button("Stop", role: .destructive) {
                Task { await stopTimer() }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Data

    /// Keep the selection pointing at an activity that exists; default to the first one.
    private func ensureValidSelection() {
        if selectedActivity == nil {
            selectedActivityId = activityStore.activities.first?.id
        }
    }

    private func stopTimer() async {
        guard let startedAt else { return }
        self.startedAt = nil

        guard let userId = authManager.currentUserId else {
            errorMessage = "You're not signed in."
            return
        }
        guard let activityId = selectedActivityId else {
            errorMessage = "Choose an activity before tracking."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            _ = try await sessionService.createSession(
                userId: userId,
                activityId: activityId,
                nfcTagId: nil,
                date: startedAt,
                duration: Date.now.timeIntervalSince(startedAt)
            )
            print("✅ Saved session")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error saving session: \(error)")
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthManager())
        .environmentObject(ActivityStore())
}
