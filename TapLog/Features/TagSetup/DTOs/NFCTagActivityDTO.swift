//
//  NFCTagActivityDTO.swift
//  TapLog
//
//  Created by Sheena Kaw on 11/4/26.
//

import Foundation

struct NFCTagActivityDTO: Codable, Identifiable, Hashable {
    let id: UUID
    let createdAt: Date
    let tagId: UUID?
    let activityId: UUID?
    
    // Optional: embedded objects when doing joins
    var tag: NFCTagDTO?
    var activity: ActivityDTO?
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case tagId = "tag_id"
        case activityId = "activity_id"
        case tag
        case activity
    }
}
