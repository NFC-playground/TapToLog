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
        let response = try await client
            .from("activities")
            .select("*")
            .eq("user_id", value: userId.uuidString)
            .order("name", ascending: true)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let activities = try decoder.decode([ActivityDTO].self, from: response.data)
        return activities
    }
    
    /// Fetch all activities (for admin/debug)
    func fetchAllActivities() async throws -> [ActivityDTO] {
        let response = try await client
            .from("activities")
            .select("""
                *,
                user:users(*)
            """)
            .order("name", ascending: true)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let activities = try decoder.decode([ActivityDTO].self, from: response.data)
        return activities
    }
    
    /// Fetch a single activity by ID
    func fetchActivity(id: UUID) async throws -> ActivityDTO? {
        let response = try await client
            .from("activities")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let activity = try? decoder.decode(ActivityDTO.self, from: response.data)
        return activity
    }
    
    // MARK: - Create Methods
    
    /// Create a new activity
    func createActivity(_ activity: ActivityDTO) async throws -> ActivityDTO {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let response = try await client
            .from("activities")
            .insert(activity)
            .select()
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let createdActivity = try decoder.decode(ActivityDTO.self, from: response.data)
        return createdActivity
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
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let response = try await client
            .from("activities")
            .update(activity)
            .eq("id", value: activity.id.uuidString)
            .select()
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let updatedActivity = try decoder.decode(ActivityDTO.self, from: response.data)
        return updatedActivity
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
