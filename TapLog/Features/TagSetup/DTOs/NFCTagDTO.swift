//
//  NFCTagDTO.swift
//  TapLog
//
//  Created by Sheena Kaw on 11/4/26.
//

import Foundation

struct NFCTagDTO: Codable, Identifiable, Hashable {
    let id: UUID
    let tagIdentifier: String
    let name: String
    let createdAt: Date
    let ownerId: UUID?
    let defaultActivityId: UUID?
    
    // Optional: embedded objects when doing joins
    var owner: UserDTO?
    var defaultActivity: ActivityDTO?
    
    enum CodingKeys: String, CodingKey {
        case id
        case tagIdentifier = "tag_identifier"
        case name
        case createdAt = "created_at"
        case ownerId = "owner_id"
        case defaultActivityId = "default_activity_id"
        case owner
        case defaultActivity = "default_activity"
    }
}
