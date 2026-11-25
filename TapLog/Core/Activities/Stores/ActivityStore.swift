//
//  ActivityStore.swift
//  TapLog
//
//  Created by Sheena Kaw on 11/9/26.
//
import Foundation
import Combine

@MainActor
final class ActivityStore: ObservableObject {

    /// Active activities: shown in Settings and in the Home picker
    @Published private(set) var activities: [ActivityDTO] = []
    /// Archived activities: hidden from Home, kept so past sessions keep their name
    @Published private(set) var archivedActivities: [ActivityDTO] = []
    @Published var errorMessage: String?

    private let service: ActivityService
    private let sessionService: TrackingSessionService

    init(service: ActivityService? = nil, sessionService: TrackingSessionService? = nil) {
        self.service = service ?? ActivityService()
        self.sessionService = sessionService ?? TrackingSessionService()
    }

    // MARK: - Load

    func load(userId: UUID) async {
        do {
            let all = try await service.fetchActivities(forUserId: userId)
            activities = all.filter { $0.archivedAt == nil }
            archivedActivities = all.filter { $0.archivedAt != nil }
        } catch {
            errorMessage = "Could not load activities: \(error.localizedDescription)"
        }
    }

    // MARK: - Add

    func add(name: String, description: String? = nil, userId: UUID) async {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        do {
            let created = try await service.createActivity(name: name, description: description, userId: userId)
            activities.append(created)
            sortActivities()
        } catch {
            errorMessage = "Could not add activity: \(error.localizedDescription)"
        }
    }

    // MARK: - Rename

    func rename(_ activity: ActivityDTO, to newName: String) async {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name != activity.name else { return }
        do {
            let updated = try await service.renameActivity(id: activity.id, to: name)
            replace(updated)
        } catch {
            errorMessage = "Could not rename activity: \(error.localizedDescription)"
        }
    }

    // MARK: - Archive / Restore

    /// Hides the activity from the list and Home picker. Its sessions are kept.
    func archive(_ activity: ActivityDTO) async {
        do {
            let updated = try await service.setArchived(id: activity.id, archivedAt: .now)
            activities.removeAll { $0.id == activity.id }
            archivedActivities.append(updated)
            sortActivities()
        } catch {
            errorMessage = "Could not archive activity: \(error.localizedDescription)"
        }
    }

    func restore(_ activity: ActivityDTO) async {
        do {
            let updated = try await service.setArchived(id: activity.id, archivedAt: nil)
            archivedActivities.removeAll { $0.id == activity.id }
            activities.append(updated)
            sortActivities()
        } catch {
            errorMessage = "Could not restore activity: \(error.localizedDescription)"
        }
    }

    // MARK: - Delete Permanently

    /// What a permanent delete would remove, shown in the confirmation.
    struct DeletionSummary {
        let sessionCount: Int
        let totalSeconds: TimeInterval
    }

    func deletionSummary(for activity: ActivityDTO) async -> DeletionSummary? {
        do {
            let sessions = try await sessionService.fetchSessions(forActivityId: activity.id)
            return DeletionSummary(
                sessionCount: sessions.count,
                totalSeconds: sessions.reduce(0) { $0 + $1.duration }
            )
        } catch {
            errorMessage = "Could not load sessions: \(error.localizedDescription)"
            return nil
        }
    }

    /// Deletes the activity and all of its sessions. Can't be undone.
    func deletePermanently(_ activity: ActivityDTO) async {
        do {
            // Sessions first, so no session is left pointing at a missing activity.
            try await sessionService.deleteSessions(forActivityId: activity.id)
            try await service.deleteActivity(id: activity.id)
            activities.removeAll { $0.id == activity.id }
            archivedActivities.removeAll { $0.id == activity.id }
        } catch {
            errorMessage = "Could not delete activity: \(error.localizedDescription)"
        }
    }

    // MARK: - Helpers

    /// Swap in an updated activity, whichever list it's in.
    private func replace(_ updated: ActivityDTO) {
        if let index = activities.firstIndex(where: { $0.id == updated.id }) {
            activities[index] = updated
        }
        if let index = archivedActivities.firstIndex(where: { $0.id == updated.id }) {
            archivedActivities[index] = updated
        }
        sortActivities()
    }

    /// Keep both lists alphabetical, case-insensitive
    private func sortActivities() {
        let byName: (ActivityDTO, ActivityDTO) -> Bool = {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        activities.sort(by: byName)
        archivedActivities.sort(by: byName)
    }
}
