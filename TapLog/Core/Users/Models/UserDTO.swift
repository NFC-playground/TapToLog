//
//  UserDTO.swift
//  TapLog
//
//  Created by Sheena Kaw on 11/4/26.
//

import Foundation

/// A row in `public.profiles`. `id` is the user's auth.users id.
/// Email isn't stored here; it lives in Supabase Auth (`AuthManager.currentUserEmail`).
struct UserDTO: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt = "created_at"
    }
}
