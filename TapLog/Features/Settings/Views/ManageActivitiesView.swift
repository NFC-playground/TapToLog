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

    @State private var activityToRename: ActivityDTO?
    @State private var renameText = ""

    @State private var activityToArchive: ActivityDTO?
    @State private var pendingDeletion: PendingDeletion?

    /// An activity waiting for permanent-delete confirmation, plus what it would remove.
    private struct PendingDeletion {
        let activity: ActivityDTO
        let summary: ActivityStore.DeletionSummary
    }

    // The body is built in stages (list → alerts → dialogs → error alert).
    // One long modifier chain was too complex for the compiler to type-check in time.
    var body: some View {
        listWithDialogs
            .alert("Something Went Wrong", isPresented: errorBinding) {
                Button("OK") { }
            } message: {
                Text(activityStore.errorMessage ?? "")
            }
    }

    // MARK: - List

    private var activityList: some View {
        List {
            activeSection
            archivedSection
        }
        .navigationTitle("Activities")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddAlert = true
                } label: {
                    Label("Add Activity", systemImage: "plus")
                }
            }
        }
    }

    private var hasOnlyArchived: Bool {
        !activityStore.archivedActivities.isEmpty
    }

    private var emptyTitle: String {
        if hasOnlyArchived { return "No active activities" }
        return "No activities yet"
    }

    private var emptyDescription: String {
        if hasOnlyArchived { return "Tap + to add one, or restore one from Archived below" }
        return "Tap + to add something you want to track"
    }

    private var activeSection: some View {
        Section {
            if activityStore.activities.isEmpty {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: "list.bullet",
                    description: Text(emptyDescription)
                )
            } else {
                ForEach(activityStore.activities) { activity in
                    activeRow(activity)
                }
            }
        }
    }

    @ViewBuilder
    private var archivedSection: some View {
        if !activityStore.archivedActivities.isEmpty {
            Section {
                ForEach(activityStore.archivedActivities) { activity in
                    archivedRow(activity)
                }
            } header: {
                Text("Archived")
            } footer: {
                Text("Archived activities are hidden from Home, and their sessions stay in History. Swipe to restore or delete permanently.")
            }
        }
    }

    /// Tap to rename; swipe left to archive (asks for confirmation first).
    private func activeRow(_ activity: ActivityDTO) -> some View {
        Button {
            renameText = activity.name
            activityToRename = activity
        } label: {
            Text(activity.name)
                .foregroundStyle(.primary)
        }
        .tint(.primary)
        .swipeActions {
            Button {
                activityToArchive = activity
            } label: {
                Label("Archive", systemImage: "archivebox")
            }
            .tint(.orange)
        }
    }

    /// Swipe left to restore or delete permanently.
    private func archivedRow(_ activity: ActivityDTO) -> some View {
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

    // MARK: - Alerts

    private var listWithAlerts: some View {
        activityList
            .newActivityAlert(isPresented: $showingAddAlert)
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
    }

    // MARK: - Confirmation Dialogs

    private var listWithDialogs: some View {
        listWithAlerts
            .confirmationDialog(
                archiveTitle,
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
            .confirmationDialog(
                deleteTitle,
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
    }

    // Titles built as plain Strings: interpolating `x ?? "..."` inside a
    // string literal is slow for the compiler to type-check.
    private var archiveTitle: String {
        let name = activityToArchive?.name ?? "activity"
        return "Archive \(name)?"
    }

    private var deleteTitle: String {
        let name = pendingDeletion?.activity.name ?? "activity"
        return "Delete \(name) permanently?"
    }

    // MARK: - Actions

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
