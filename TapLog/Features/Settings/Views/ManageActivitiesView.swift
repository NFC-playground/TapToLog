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

    @State private var showingAddAlert = false
    @State private var newActivityName = ""

    var body: some View {
        List {
            if activityStore.activities.isEmpty {
                ContentUnavailableView(
                    "No activities yet",
                    systemImage: "list.bullet",
                    description: Text("Tap + to add something you want to track")
                )
            } else {
                ForEach(activityStore.activities) { activity in
                    Text(activity.name)
                }
                // TODO: rename (tap a row) and delete (swipe) once the store supports them
            }
        }
        .navigationTitle("Activities")
        .toolbar {
            //primary action is top right corner
            ToolbarItem(placement: .primaryAction) {
                Button {
                    newActivityName = ""
                    showingAddAlert = true
                } label: {
                    // plus icon for adding new acitivity
                    Label("Add Activity", systemImage: "plus")
                }
            }
        }
        // $ -> binding, alert opens when true
        // sets back to false when tapping any enabled button (add or cancel)
        .alert("New Activity", isPresented: $showingAddAlert) {
            TextField("Name", text: $newActivityName)
                .textInputAutocapitalization(.words)
            Button("Cancel", role: .cancel) { }
            Button("Add") {
                Task { await addActivity() }
            }
            // View-level check: the store also guards against blank names
            .disabled(trimmedName.isEmpty)
        }
        .alert("Something Went Wrong", isPresented: errorBinding) {
            Button("OK") { }
        } message: {
            Text(activityStore.errorMessage ?? "")
        }
    }

    // MARK: - Helpers

    private var trimmedName: String {
        newActivityName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Shows the alert while the store has an error; dismissing it clears the error.
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { activityStore.errorMessage != nil },
            set: { if !$0 { activityStore.errorMessage = nil } }
        )
    }

    private func addActivity() async {
        guard let userId = authManager.currentUserId else { return }
        await activityStore.add(name: trimmedName, userId: userId)
    }
}

#Preview {
    NavigationStack {
        ManageActivitiesView()
    }
    .environmentObject(AuthManager())
    .environmentObject(ActivityStore())
}
