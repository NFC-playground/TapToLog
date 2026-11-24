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
    // app storage writes to UserDefaults which is saved on disk
    @AppStorage("activeTimer.activityId") private var storedActivityId: String?
    // Changing the variable redraws the view. When storedStartedAt changes, SwiftUI runs body again.
    @AppStorage("activeTimer.userId") private var storedUserId: String?
    
    @State private var selectedActivityId: UUID?
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    /// Completed sessions for the summaries, newest first.
    @State private var sessions: [TrackingSessionDTO] = []
    
    // MARK: - Derived state

    // runningTimer is a computed property so every time its read
    // swfit executes the following code and returns a RunningTimer or Nil
    private var runningTimer: RunningTimer? {
        // the gaurd means all lines must succeed otherwise jumps out to else statemnet
        guard let storedStartedAt,
              // comes from the app storage
              let activityId = storedActivityId.flatMap(UUID.init(uuidString:)),
              let userId = storedUserId.flatMap(UUID.init(uuidString:)),
              // check if above user id is the signed in user
              userId == authManager.currentUserId
                else { return nil }
        
        return RunningTimer(
            activityId: activityId,
            userId: userId,
            startedAt: Date(timeIntervalSince1970: storedStartedAt)
        )
    }
    
    /// The activity the running timer is tracking.
    /// gets the activity that matches the currently stored activity
    private var runningActivity: ActivityDTO? {
        activityStore.activities.first { $0.id == runningTimer?.activityId }
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
            // Group applies the navigationTitle, onChange functions to both views inside
            Group {
                // there is a current running timer
                if let runningTimer {
                    RunningTimerView(
                        activityName: runningActivity?.name ?? "Unknown activity",
                        startedAt: runningTimer.startedAt,
                        isSaving: isSaving,
                        onStop: {Task {await stopTimer()} }
                    )
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
        guard let timer = runningTimer
                else { return }
        
        isSaving = true
        // is saving alwayd returns false at the end of function run
        defer {
            isSaving = false
        }
        
        do {
            _ = try await sessionService.createSession(
                userId: timer.userId,
                activityId: timer.activityId,
                nfcTagId: nil,
                date: timer.startedAt,
                duration: Date.now.timeIntervalSince(timer.startedAt)
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
