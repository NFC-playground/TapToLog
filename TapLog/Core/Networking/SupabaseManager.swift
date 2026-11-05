//
//  SupabaseManager.swift
//  TapLog
//
//  Created by Sheena Kaw on 10/25/26.
//

import Foundation
import Supabase

/// Holds the single shared Supabase client.
/// `SupabaseClient` is thread-safe (Sendable), so this doesn't need to live on the main actor.
final class SupabaseManager: Sendable {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        guard let supabaseURL = URL(string: Secrets.supabaseURL) else {
            fatalError("Invalid Supabase URL in Secrets.swift")
        }

        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: Secrets.supabaseKey
        )
    }
}
