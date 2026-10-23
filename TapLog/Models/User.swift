//
//  User.swift
//  TapLog
//
//  Created by Sheena Kaw on 10/22/26.
//

import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    
    // Relationships
    
    // inverse means linking Activity.user to a User from this class
    // 1 user can have many Activity
    @Relationship(deleteRule: .cascade, inverse: \Activity.user)
    var activities: [Activity] = []
    
    //deleteRule: .cascade -> if a user gets deleted their NFC tag gets deleted
    @Relationship(deleteRule: .cascade, inverse: \NFCTag.owner)
    var nfcTags: [NFCTag] = []
    
    @Relationship(deleteRule: .cascade, inverse: \TrackingSession.user)
    var trackingSessions: [TrackingSession] = []
    
    init(id: UUID = UUID(), name: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}

