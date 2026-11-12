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

    // The running timer is saved on the phone (UserDefaults) so it survives
    // the app being closed. nil means no timer is running.
    @AppStorage("activeTimer.startedAt") private var storedStartedAt: Double?
    @AppStorage("activeTimer.activityId") private var storedActivityId: String?
    @AppStorage("activeTimer.userId") private var storedUserId: String?

    @State private var selectedActivityId: UUID?
    @State private var isSaving = false
    @State private var errorMessage: String?

    /// Completed sessions for the summaries, newest first.
    @State private var sessions: [TrackingSessionDTO] = []

    // MARK: - Derived state

    /// When the running timer started, but only if it belongs to the signed-in user.
    private var startedAt: Date? {
        guard let storedStartedAt,
              storedUserId == authManager.currentUserId?.uuidString
        else { return nil }
        return Date(timeIntervalSince1970: storedStartedAt)
    }

    /// The activity the running timer is tracking.
    private var runningActivity: ActivityDTO? {
        activityStore.activities.first { $0.id.uuidString == storedActivityId }
    }

    private var selectedActivity: ActivityDTO? {
        activityStore.activities.first { $0.id == selectedActivityId }
    }

    private var todayTotal: TimeInterval {
        SessionStats.totalDuration(of: sessions, since: SessionStats.startOfToday())
    }

    private var weekTotal: TimeInterval {
        SessionStats.totalDuration(of: sessions, since: SessionStats.startOfWeek())
    }

    private var recentSessions: [TrackingSessionDTO] {
        Array(sessions.prefix(5))
    }

    // MARK: - Body

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
            // Runs on first appear and whenever the list changes, so the
            // picker always points at a real activity.
            .onChange(of: activityStore.activities, initial: true) {
                ensureValidSelection()
            }
            .task {
                await loadSessions()
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

    // MARK: - Idle

    private var idleView: some View {
        ScrollView {
            VStack(spacing: 32) {
                startSection
                summarySection
            }
            .padding()
        }
        .refreshable {
            await loadSessions()
        }
    }

    private var startSection: some View {
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
                startTimer()
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedActivityId == nil)
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                statCard(title: "Today", seconds: todayTotal)
                statCard(title: "This week", seconds: weekTotal)
            }

            if !recentSessions.isEmpty {
                Text("Recent")
                    .font(.headline)

                ForEach(recentSessions) { session in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.activity?.name ?? "Unknown activity")
                            Text(session.date, format: .dateTime.month().day().hour().minute())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(DurationFormat.short(session.duration))
                            .monospacedDigit()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func statCard(title: String, seconds: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(DurationFormat.short(seconds))
                .font(.title2.bold())
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Running

    private func runningView(startedAt: Date) -> some View {
        VStack(spacing: 24) {
            Text(runningActivity?.name ?? "Unknown activity")
                .font(.title2)
            Text(startedAt, style: .timer)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()

            Button(role: .destructive) {
                Task { await stopTimer() }
            } label: {
                if isSaving {
                    ProgressView()
                } else {
                    Text("Stop")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSaving)
        }
    }

    // MARK: - Actions

    private func startTimer() {
        guard let selectedActivityId,
              let userId = authManager.currentUserId
        else { return }

        storedActivityId = selectedActivityId.uuidString
        storedUserId = userId.uuidString
        storedStartedAt = Date.now.timeIntervalSince1970
    }

    private func stopTimer() async {
        guard let startedAt else { return }

        guard let userId = authManager.currentUserId else {
            errorMessage = "You're not signed in."
            return
        }
        guard let activityIdString = storedActivityId,
              let activityId = UUID(uuidString: activityIdString)
        else {
            errorMessage = "This timer has no activity. It was cleared."
            clearActiveTimer()
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
            // Only clear the timer once the session is safely saved.
            clearActiveTimer()
            await loadSessions()
        } catch {
            // The timer keeps running, so tapping Stop again retries the save.
            errorMessage = "\(error.localizedDescription) Your timer is still running. Tap Stop to try again."
        }
    }

    private func clearActiveTimer() {
        storedStartedAt = nil
        storedActivityId = nil
        storedUserId = nil
    }

    /// Keep the picker pointing at an activity that exists; default to the first one.
    private func ensureValidSelection() {
        if selectedActivity == nil {
            selectedActivityId = activityStore.activities.first?.id
        }
    }

    // MARK: - Data

    private func loadSessions() async {
        guard let userId = authManager.currentUserId else { return }
        do {
            sessions = try await sessionService.fetchSessions(forUserId: userId)
        } catch {
            // Summaries are a nice-to-have; keep the screen usable if this fails.
            print("❌ Error loading sessions for summaries: \(error)")
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthManager())
        .environmentObject(ActivityStore())
}
