//
//  ActivityService.swift
//  TapLog
//
//  Created by Sheena Kaw on 11/4/26.
//

import Foundation
import Supabase

@MainActor
class ActivityService: ObservableObject {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }

    // MARK: - Fetch Methods

    /// Fetch all activities for a specific user
    func fetchActivities(forUserId userId: UUID) async throws -> [ActivityDTO] {
        try await client
            .from("activities")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("name", ascending: true)
            .execute()
            .value
    }

    /// Fetch all activities (for admin/debug)
    func fetchAllActivities() async throws -> [ActivityDTO] {
        try await client
            .from("activities")
            .select("""
                *,
                user:users(*)
            """)
            .order("name", ascending: true)
            .execute()
            .value
    }

    /// Fetch a single activity by ID. Returns nil if no row matches.
    func fetchActivity(id: UUID) async throws -> ActivityDTO? {
        let activities: [ActivityDTO] = try await client
            .from("activities")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        return activities.first
    }

    // MARK: - Create Methods

    /// Create a new activity
    func createActivity(_ activity: ActivityDTO) async throws -> ActivityDTO {
        try await client
            .from("activities")
            .insert(activity)
            .select()
            .single()
            .execute()
            .value
    }

    /// Convenience method to create an activity
    func createActivity(
        name: String,
        description: String,
        userId: UUID
    ) async throws -> ActivityDTO {
        let activity = ActivityDTO(
            id: UUID(),
            name: name,
            activityDescription: description,
            createdAt: Date(),
            userId: userId
        )
        return try await createActivity(activity)
    }

    // MARK: - Update Methods

    /// Update an existing activity
    func updateActivity(_ activity: ActivityDTO) async throws -> ActivityDTO {
        // Strip any joined object so only real columns are sent
        var row = activity
        row.user = nil

        return try await client
            .from("activities")
            .update(row)
            .eq("id", value: activity.id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: - Delete Methods

    /// Delete an activity by ID
    func deleteActivity(id: UUID) async throws {
        try await client
            .from("activities")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
