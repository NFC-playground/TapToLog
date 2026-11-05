//
//  UserService.swift
//  TapLog
//
//  Created by Sheena Kaw on 11/4/26.
//

import Foundation
import Supabase

// `.execute().value` decodes with the Supabase SDK's own decoder, which
// understands Postgres timestamps (including fractional seconds).

@MainActor
class UserService: ObservableObject {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }

    // MARK: - Fetch Methods

    /// Fetch all users
    func fetchAllUsers() async throws -> [UserDTO] {
        try await client
            .from("users")
            .select()
            .order("name", ascending: true)
            .execute()
            .value
    }

    /// Fetch a single user by ID. Returns nil if no row matches.
    func fetchUser(id: UUID) async throws -> UserDTO? {
        let users: [UserDTO] = try await client
            .from("users")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        return users.first
    }

    /// Fetch user by email. Returns nil if no row matches.
    func fetchUser(email: String) async throws -> UserDTO? {
        let users: [UserDTO] = try await client
            .from("users")
            .select()
            .eq("email", value: email)
            .limit(1)
            .execute()
            .value
        return users.first
    }

    // MARK: - Create Methods

    /// Create a new user
    func createUser(_ user: UserDTO) async throws -> UserDTO {
        try await client
            .from("users")
            .insert(user)
            .select()
            .single()
            .execute()
            .value
    }

    /// Convenience method to create a user with just a name
    func createUser(name: String) async throws -> UserDTO {
        let user = UserDTO(
            id: UUID(),
            name: name,
            email: nil,
            createdAt: Date()
        )
        return try await createUser(user)
    }

    /// Create the user's row if it doesn't exist yet. Leaves an existing row unchanged.
    func ensureUserExists(_ user: UserDTO) async throws {
        try await client
            .from("users")
            .upsert(user, onConflict: "id", returning: .minimal, ignoreDuplicates: true)
            .execute()
    }

    // MARK: - Update Methods

    /// Update an existing user
    func updateUser(_ user: UserDTO) async throws -> UserDTO {
        try await client
            .from("users")
            .update(user)
            .eq("id", value: user.id.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    /// Update just the user's name
    func updateUserName(userId: UUID, newName: String) async throws -> UserDTO {
        struct NameUpdate: Encodable {
            let name: String
        }

        return try await client
            .from("users")
            .update(NameUpdate(name: newName))
            .eq("id", value: userId.uuidString)
            .select()
            .single()
            .execute()
            .value
    }

    // MARK: - Delete Methods

    /// Delete a user by ID
    func deleteUser(id: UUID) async throws {
        try await client
            .from("users")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Statistics

    /// Get total session count for a user
    func getUserSessionCount(userId: UUID) async throws -> Int {
        let response = try await client
            .from("tracking_sessions")
            .select("id", head: true, count: .exact)
            .eq("user_id", value: userId.uuidString)
            .execute()

        return response.count ?? 0
    }

    /// Get total activity count for a user
    func getUserActivityCount(userId: UUID) async throws -> Int {
        let response = try await client
            .from("activities")
            .select("id", head: true, count: .exact)
            .eq("user_id", value: userId.uuidString)
            .execute()

        return response.count ?? 0
    }
}
