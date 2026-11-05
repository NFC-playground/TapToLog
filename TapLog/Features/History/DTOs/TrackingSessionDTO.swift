//
//  TrackingSessionDTO.swift
//  TapLog
//
//  Created by Sheena Kaw on 11/4/26.
//

import Foundation

struct TrackingSessionDTO: Codable, Identifiable, Hashable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let sessionDescription: String?
    let userId: UUID?
    let activityId: UUID?
    let nfcTagId: UUID?
    
    // Optional: embedded objects when doing joins
    var user: UserDTO?
    var activity: ActivityDTO?
    var nfcTag: NFCTagDTO?
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case duration
        case sessionDescription = "session_description"
        case userId = "user_id"
        case activityId = "activity_id"
        case nfcTagId = "nfc_tag_id"
        case user
        case activity
        case nfcTag = "nfc_tag"
    }
}
