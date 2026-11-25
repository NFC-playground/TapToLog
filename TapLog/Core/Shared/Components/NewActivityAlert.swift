//
//  NewActivityAlert.swift
//  TapLog
//

import SwiftUI

/// The "New Activity" name prompt, shared by Home and Settings so adding
/// behaves the same wherever it's triggered.
private struct NewActivityAlert: ViewModifier {
    @Binding var isPresented: Bool
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var activityStore: ActivityStore
    @State private var name = ""

    func body(content: Content) -> some View {
        content.alert("New Activity", isPresented: $isPresented) {
            TextField("Name", text: $name)
                .textInputAutocapitalization(.words)
            Button("Cancel", role: .cancel) { name = "" }
            Button("Add") {
                let newName = name
                name = ""
                Task { await add(newName) }
            }
            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func add(_ newName: String) async {
        guard let userId = authManager.currentUserId else { return }
        await activityStore.add(name: newName, userId: userId)
    }
}

extension View {
    /// Shows the "New Activity" prompt when `isPresented` becomes true.
    func newActivityAlert(isPresented: Binding<Bool>) -> some View {
        modifier(NewActivityAlert(isPresented: isPresented))
    }
}
