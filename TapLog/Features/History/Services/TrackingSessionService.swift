//
//  TrackingSessionService.swift
//  TapLog
//
//  Created by Sheena Kaw on 11/4/26.
//

import Foundation
import Supabase

@MainActor
class TrackingSessionService: ObservableObject {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }

    // MARK: - Fetch Methods

    /// Fetch all sessions for a specific user, sorted by date (newest first)
    func fetchSessions(forUserId userId: UUID) async throws -> [TrackingSessionDTO] {
        try await client
            .from("tracking_sessions")
            .select("""
                *,
                activity:activities(*),
                nfc_tag:nfc_tags(*)
            """)
            .eq("user_id", value: userId.uuidString)
            .order("date", ascending: false)
            .execute()
            .value
    }

    /// Fetch all sessions (for admin/debug purposes)
    func fetchAllSessions() async throws -> [TrackingSessionDTO] {
        try await client
            .from("tracking_sessions")
            .select("""
                *,
                activity:activities(*),
                nfc_tag:nfc_tags(*),
                user:users(*)
            """)
            .order("date", ascending: false)
            .execute()
            .value
    }

    // MARK: - Create Methods

    /// Insert a new tracking session
    func createSession(_ session: TrackingSessionDTO) async throws -> TrackingSessionDTO {
        try await client
            .from("tracking_sessions")
            .insert(Self.columnsOnly(session))
            .select()
            .single()
            .execute()
            .value
    }

    /// Convenience method to create a session with basic info
    func createSession(
        userId: UUID,
        activityId: UUID?,
        nfcTagId: UUID?,
        date: Date = Date(),
        duration: TimeInterval,
        description: String? = nil
    ) async throws -> TrackingSessionDTO {
        let session = TrackingSessionDTO(
            id: UUID(),
            date: date,
            duration: duration,
            sessionDescription: description,
            userId: userId,
            activityId: activityId,
            nfcTagId: nfcTagId
        )

        return try await createSession(session)
    }

    // MARK: - Update Methods

    /// Update an existing session
    func updateSession(_ session: TrackingSessionDTO) async throws -> TrackingSessionDTO {
        try await client
            .from("tracking_sessions")
            .update(Self.columnsOnly(session))
            .eq("id", value: session.id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: - Delete Methods

    /// Delete a session by ID
    func deleteSession(id: UUID) async throws {
        try await client
            .from("tracking_sessions")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Delete all sessions for a user
    func deleteAllSessions(forUserId userId: UUID) async throws {
        try await client
            .from("tracking_sessions")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    // MARK: - Helpers

    /// Joined objects (activity, tag, user) aren't real columns, so drop them before writing
    private static func columnsOnly(_ session: TrackingSessionDTO) -> TrackingSessionDTO {
        var row = session
        row.user = nil
        row.activity = nil
        row.nfcTag = nil
        return row
    }
}
