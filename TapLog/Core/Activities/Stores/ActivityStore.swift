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

    // Published whenever the activities change, views reading it redraw
    @Published private(set) var activities: [ActivityDTO] = []
    @Published var errorMessage: String?

    private let service: ActivityService
    
    init(service: ActivityService? = nil) {
        self.service = service ?? ActivityService()
    }
    
    func load(userId: UUID) async {
        do {
            activities = try await service.fetchActivities(forUserId: userId)
        } catch {
            errorMessage = "Could not load activities: \(error.localizedDescription)"
        }
    }
    
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
    
    // TODO: rename function
    
    // TODO: delete function

    // MARK: - Helpers

    /// Keep the same order the server returns (alphabetical, case-insensitive)
    private func sortActivities() {
        activities.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
