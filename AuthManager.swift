//
//  AuthManager.swift
//  TapLog
//
//  Created by Sheena Kaw on 11/4/26.
//

import Foundation
import Supabase
import AuthenticationServices

@MainActor
class AuthManager: ObservableObject {
    // MARK: - Published Properties
    
    @Published var currentUser: Supabase.User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let client: SupabaseClient
    
    // MARK: - Initialization
    
    init(client: SupabaseClient? = nil) {
        self.client = client ?? SupabaseManager.shared.client
        
        // Check if user is already logged in
        Task {
            await checkSession()
        }
    }
    
    // MARK: - Session Management
    
    /// Check if there's an active session
    func checkSession() async {
        isLoading = true
        
        do {
            let session = try await client.auth.session
            currentUser = session.user
            isAuthenticated = true
            print("✅ User session found: \(session.user.email ?? "No email")")
        } catch {
            currentUser = nil
            isAuthenticated = false
            print("ℹ️ No active session")
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Up
    
    /// Sign up a new user with email and password
    func signUp(email: String, password: String, name: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            // Sign up with Supabase Auth
            let response = try await client.auth.signUp(
                email: email,
                password: password,
                data: ["name": .string(name)] // Store name in user metadata
            )
            
            currentUser = response.user
            isAuthenticated = true
            
            // Create corresponding user in your users table
            let userService = UserService()
            _ = try await userService.createUser(
                UserDTO(
                    id: UUID(uuidString: response.user.id.uuidString) ?? UUID(),
                    name: name,
                    email: email,
                    createdAt: Date()
                )
            )
            
            print("✅ User signed up: \(email)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Sign up error: \(error)")
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Sign In
    
    /// Sign in an existing user with email and password
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            
            currentUser = session.user
            isAuthenticated = true
            
            print("✅ User signed in: \(email)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Sign in error: \(error)")
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Out
    
    /// Sign out the current user
    func signOut() async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            try await client.auth.signOut()
            currentUser = nil
            isAuthenticated = false
            
            print("✅ User signed out")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Sign out error: \(error)")
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Password Reset
    
    /// Send password reset email
    func resetPassword(email: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            try await client.auth.resetPasswordForEmail(email)
            print("✅ Password reset email sent to: \(email)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Password reset error: \(error)")
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Properties
    
    /// Get current user's ID as UUID
    var currentUserId: UUID? {
        guard let user = currentUser else { return nil }
        return UUID(uuidString: user.id.uuidString)
    }
    
    /// Get current user's email
    var currentUserEmail: String? {
        currentUser?.email
    }
    
    /// Get current user's name from metadata
    var currentUserName: String? {
        currentUser?.userMetadata["name"]?.stringValue
    }
}
