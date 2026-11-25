//
//  ManageActivitiesView.swift
//  TapLog
//

import SwiftUI

/// Lets the user build the list of activities they track (Reading, Piano, ...).
/// The list comes from the shared `ActivityStore`, so Home's picker updates too.
struct ManageActivitiesView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var activityStore: ActivityStore

    /// The activity a running timer is tracking (saved by HomeView).
    /// It can't be permanently deleted while the timer runs.
    @AppStorage("activeTimer.activityId") private var runningActivityId: String?

    @State private var showingAddAlert = false
    @State private var newActivityName = ""

    @State private var activityToRename: ActivityDTO?
    @State private var renameText = ""

    @State private var activityToArchive: ActivityDTO?
    @State private var pendingDeletion: PendingDeletion?

    /// An activity waiting for permanent-delete confirmation, plus what it would remove.
    private struct PendingDeletion {
        let activity: ActivityDTO
        let summary: ActivityStore.DeletionSummary
    }

    var body: some View {
        List {
            // MARK: Active
            Section {
                if activityStore.activities.isEmpty {
                    ContentUnavailableView(
                        "No activities yet",
                        systemImage: "list.bullet",
                        description: Text("Tap + to add something you want to track")
                    )
                } else {
                    ForEach(activityStore.activities) { activity in
                        // Tap a row to rename it
                        Button {
                            renameText = activity.name
                            activityToRename = activity
                        } label: {
                            Text(activity.name)
                                .foregroundStyle(.primary)
                        }
                        // Swipe left to archive (asks for confirmation first)
                        .swipeActions {
                            Button {
                                activityToArchive = activity
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                            .tint(.orange)
                        }
                    }
                }
            }

            // MARK: Archived
            if !activityStore.archivedActivities.isEmpty {
                Section {
                    ForEach(activityStore.archivedActivities) { activity in
                        Text(activity.name)
                            .foregroundStyle(.secondary)
                            .swipeActions {
                                // First button is what a full swipe triggers, so keep the safe one first.
                                Button {
                                    Task { await activityStore.restore(activity) }
                                } label: {
                                    Label("Restore", systemImage: "arrow.uturn.backward")
                                }
                                .tint(.blue)

                                Button {
                                    Task { await prepareDeletion(of: activity) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                    }
                } header: {
                    Text("Archived")
                } footer: {
                    Text("Archived activities are hidden from Home, and their sessions stay in History. Swipe to restore or delete permanently.")
                }
            }
        }
        .navigationTitle("Activities")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    newActivityName = ""
                    showingAddAlert = true
                } label: {
                    Label("Add Activity", systemImage: "plus")
                }
            }
        }
        // MARK: Add
        .alert("New Activity", isPresented: $showingAddAlert) {
            TextField("Name", text: $newActivityName)
                .textInputAutocapitalization(.words)
            Button("Cancel", role: .cancel) { }
            Button("Add") {
                Task { await addActivity() }
            }
            .disabled(trimmed(newActivityName).isEmpty)
        }
        // MARK: Rename
        .alert(
            "Rename Activity",
            isPresented: isPresenting($activityToRename),
            presenting: activityToRename
        ) { activity in
            TextField("Name", text: $renameText)
                .textInputAutocapitalization(.words)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                Task { await activityStore.rename(activity, to: renameText) }
            }
            .disabled(trimmed(renameText).isEmpty)
        }
        // MARK: Archive confirmation
        .confirmationDialog(
            "Archive \(activityToArchive?.name ?? "activity")?",
            isPresented: isPresenting($activityToArchive),
            titleVisibility: .visible,
            presenting: activityToArchive
        ) { activity in
            Button("Archive") {
                Task { await activityStore.archive(activity) }
            }
            Button("Cancel", role: .cancel) { }
        } message: { _ in
            Text("It will be hidden from your list and Home. Past sessions stay in History, and you can restore it anytime.")
        }
        // MARK: Permanent delete confirmation
        .confirmationDialog(
            "Delete \(pendingDeletion?.activity.name ?? "activity") permanently?",
            isPresented: isPresenting($pendingDeletion),
            titleVisibility: .visible,
            presenting: pendingDeletion
        ) { pending in
            Button("Delete Permanently", role: .destructive) {
                Task { await activityStore.deletePermanently(pending.activity) }
            }
            Button("Cancel", role: .cancel) { }
        } message: { pending in
            Text(deletionMessage(pending.summary))
        }
        // MARK: Errors
        .alert("Something Went Wrong", isPresented: errorBinding) {
            Button("OK") { }
        } message: {
            Text(activityStore.errorMessage ?? "")
        }
    }

    // MARK: - Actions

    private func addActivity() async {
        guard let userId = authManager.currentUserId else { return }
        await activityStore.add(name: trimmed(newActivityName), userId: userId)
    }

    /// Loads what a permanent delete would remove, then shows the confirmation.
    private func prepareDeletion(of activity: ActivityDTO) async {
        if activity.id.uuidString == runningActivityId {
            activityStore.errorMessage = "Stop the running timer for \(activity.name) before deleting it."
            return
        }
        guard let summary = await activityStore.deletionSummary(for: activity) else { return }
        pendingDeletion = PendingDeletion(activity: activity, summary: summary)
    }

    // MARK: - Helpers

    private func deletionMessage(_ summary: ActivityStore.DeletionSummary) -> String {
        let time = DurationFormat.short(summary.totalSeconds)
        switch summary.sessionCount {
        case 0:
            return "It has no sessions. This can't be undone."
        case 1:
            return "This also deletes 1 session (\(time)) from History and your totals. This can't be undone."
        default:
            return "This also deletes \(summary.sessionCount) sessions (\(time)) from History and your totals. This can't be undone."
        }
    }

    private func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Turns "an optional item" into "is this alert showing". Dismissing sets the item back to nil.
    private func isPresenting<T>(_ item: Binding<T?>) -> Binding<Bool> {
        Binding(
            get: { item.wrappedValue != nil },
            set: { if !$0 { item.wrappedValue = nil } }
        )
    }

    /// Shows the alert while the store has an error; dismissing it clears the error.
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { activityStore.errorMessage != nil },
            set: { if !$0 { activityStore.errorMessage = nil } }
        )
    }
}

#Preview {
    NavigationStack {
        ManageActivitiesView()
    }
    .environmentObject(AuthManager())
    .environmentObject(ActivityStore())
}
