//
//  UserService.swift
//  TapLog
//
//  Created by Sheena Kaw on 11/4/26.
//

import Foundation
import Supabase

@MainActor
class UserService: ObservableObject {
    private let client: SupabaseClient
    
    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }
    
    // MARK: - Fetch Methods
    
    /// Fetch all users
    func fetchAllUsers() async throws -> [UserDTO] {
        let response = try await client
            .from("users")
            .select()
            .order("name", ascending: true)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let users = try decoder.decode([UserDTO].self, from: response.data)
        return users
    }
    
    /// Fetch a single user by ID
    func fetchUser(id: UUID) async throws -> UserDTO? {
        let response = try await client
            .from("users")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let user = try? decoder.decode(UserDTO.self, from: response.data)
        return user
    }
    
    /// Fetch user by email (useful for auth)
    func fetchUser(email: String) async throws -> UserDTO? {
        let response = try await client
            .from("users")
            .select()
            .eq("email", value: email)
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let user = try? decoder.decode(UserDTO.self, from: response.data)
        return user
    }
    
    // MARK: - Create Methods
    
    /// Create a new user
    func createUser(_ user: UserDTO) async throws -> UserDTO {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let response = try await client
            .from("users")
            .insert(user)
            .select()
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let createdUser = try decoder.decode(UserDTO.self, from: response.data)
        return createdUser
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
    
    // MARK: - Update Methods
    
    /// Update an existing user
    func updateUser(_ user: UserDTO) async throws -> UserDTO {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let response = try await client
            .from("users")
            .update(user)
            .eq("id", value: user.id.uuidString)
            .select()
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let updatedUser = try decoder.decode(UserDTO.self, from: response.data)
        return updatedUser
    }
    
    /// Update just the user's name
    func updateUserName(userId: UUID, newName: String) async throws -> UserDTO {
        struct NameUpdate: Encodable {
            let name: String
        }
        
        let response = try await client
            .from("users")
            .update(NameUpdate(name: newName))
            .eq("id", value: userId.uuidString)
            .select()
            .single()
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let updatedUser = try decoder.decode(UserDTO.self, from: response.data)
        return updatedUser
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
            .select("id", count: .exact)
            .eq("user_id", value: userId.uuidString)
            .execute()
        
        return response.count ?? 0
    }
    
    /// Get total activity count for a user
    func getUserActivityCount(userId: UUID) async throws -> Int {
        let response = try await client
            .from("activities")
            .select("id", count: .exact)
            .eq("user_id", value: userId.uuidString)
            .execute()
        
        return response.count ?? 0
    }
}
