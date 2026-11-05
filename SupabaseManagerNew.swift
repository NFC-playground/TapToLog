//
//  SupabaseManager.swift
//  TapLog
//
//  Created by Sheena Kaw on 10/25/26.
//

import Foundation
import Supabase

@MainActor
class SupabaseManager: ObservableObject {
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

// Convenience global accessor (optional - for backward compatibility)
let supabase = SupabaseManager.shared.client
