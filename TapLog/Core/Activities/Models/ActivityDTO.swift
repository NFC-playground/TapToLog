//
//  ActivityDTO.swift
//  TapLog
//
//  Created by Sheena Kaw on 11/4/26.
//

import Foundation

struct ActivityDTO: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let activityDescription: String?   // nullable in the `activities` table
    let createdAt: Date
    let userId: UUID?
    
    // Optional: embedded user object when doing joins
    var user: UserDTO?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case activityDescription = "activity_description"
        case createdAt = "created_at"
        case userId = "user_id"
        case user
    }
}
