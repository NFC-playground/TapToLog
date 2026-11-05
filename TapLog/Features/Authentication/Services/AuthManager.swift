//
//  AuthManager.swift
//  TapLog
//
//  Created by Sheena Kaw on 11/4/26.
//

import Foundation
import Supabase

@MainActor
class AuthManager: ObservableObject {
    // MARK: - Published Properties

    @Published var currentUser: Supabase.User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    /// True only until the first auth state arrives on launch
    @Published var isCheckingSession = true
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let client: SupabaseClient
    private let userService: UserService

    // MARK: - Initialization

    init(client: SupabaseClient? = nil) {
        let client = client ?? SupabaseManager.shared.client
        self.client = client
        self.userService = UserService(client: client)

        // Follow every auth change (launch, sign in/out, token refresh, expiry)
        // so the UI always matches the real session.
        Task { [weak self] in
            guard let stream = self?.client.auth.authStateChanges else { return }
            for await (event, session) in stream {
                guard let self else { return }
                self.apply(event: event, session: session)
            }
        }
    }

    // MARK: - Session Management

    private func apply(event: AuthChangeEvent, session: Session?) {
        currentUser = session?.user
        isAuthenticated = (session != nil)
        isCheckingSession = false

        if let session, event == .initialSession || event == .signedIn {
            Task { await ensureUserRow(for: session.user) }
        }
    }

    /// Make sure the signed-in user has a row in the `users` table.
    /// Done here (with a real session) rather than at sign-up, because when email
    /// confirmation is on, sign-up returns no session and RLS would block the insert.
    private func ensureUserRow(for user: Supabase.User) async {
        let name = user.userMetadata["name"]?.stringValue
            ?? user.email?.components(separatedBy: "@").first
            ?? "User"

        do {
            try await userService.ensureUserExists(
                UserDTO(id: user.id, name: name, email: user.email, createdAt: Date())
            )
        } catch {
            print("❌ Could not create users row: \(error)")
        }
    }

    // MARK: - Sign Up

    enum SignUpResult {
        /// Signed in straight away
        case signedIn
        /// Account created, but the user must confirm their email before signing in
        case needsEmailConfirmation
    }

    /// Sign up a new user with email and password
    func signUp(email: String, password: String, name: String) async throws -> SignUpResult {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password,
                data: ["name": .string(name)] // Store name in user metadata
            )

            // The auth state listener updates currentUser / isAuthenticated
            // and creates the users row once a session exists.
            print("✅ User signed up: \(email)")
            return response.session == nil ? .needsEmailConfirmation : .signedIn
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Sign up error: \(error)")
            throw error
        }
    }

    // MARK: - Sign In

    /// Sign in an existing user with email and password
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            try await client.auth.signIn(email: email, password: password)
            print("✅ User signed in: \(email)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Sign in error: \(error)")
            throw error
        }
    }

    // MARK: - Sign Out

    /// Sign out the current user
    func signOut() async throws {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            try await client.auth.signOut()
            print("✅ User signed out")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Sign out error: \(error)")
            throw error
        }
    }

    // MARK: - Password Reset

    /// Send password reset email
    func resetPassword(email: String) async throws {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            try await client.auth.resetPasswordForEmail(email)
            print("✅ Password reset email sent to: \(email)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Password reset error: \(error)")
            throw error
        }
    }

    // MARK: - Helper Properties

    /// Get current user's ID
    var currentUserId: UUID? {
        currentUser?.id
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
