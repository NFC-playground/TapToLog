//
//  NFCTag.swift
//  TapLog
//
//  Created by Sheena Kaw on 10/22/26.
//

import Foundation
import SwiftData

@Model
final class NFCTag {
    var id: UUID
    var tagIdentifier: String // The actual NFC tag ID
    var name: String
    var createdAt: Date
    
    // Relationships
    var owner: User?
    
    @Relationship(deleteRule: .cascade, inverse: \NFCTagActivity.tag)
    var activityLinks: [NFCTagActivity] = []
    
    var defaultActivity: Activity?
    
    @Relationship(deleteRule: .nullify, inverse: \TrackingSession.nfcTag)
    var trackingSessions: [TrackingSession] = []
    
    init(
        id: UUID = UUID(),
        tagIdentifier: String,
        name: String,
        createdAt: Date = Date(),
        owner: User? = nil,
        defaultActivity: Activity? = nil
    ) {
        self.id = id
        self.tagIdentifier = tagIdentifier
        self.name = name
        self.createdAt = createdAt
        self.owner = owner
        self.defaultActivity = defaultActivity
    }
}
