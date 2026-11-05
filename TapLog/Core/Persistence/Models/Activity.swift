//
//  Activity.swift
//  TapLog
//
//  Created by Sheena Kaw on 10/22/26.
//

import Foundation
import SwiftData

@Model
final class Activity {
    var id: UUID
    var name: String
    var activityDescription: String // "reading" or "programming"
    var createdAt: Date
    
    // Relationships
    // like a FK points to a User
    // 1 activity can have at most 1 user
    var user: User?
    
    @Relationship(deleteRule: .cascade, inverse: \NFCTagActivity.activity)
    var tagLinks: [NFCTagActivity] = []
    
    //deleteRule: .nullify -> if a Acitivity gets deleted the TrackingSession's activity becomes null
    @Relationship(deleteRule: .nullify, inverse: \TrackingSession.activity)
    var trackingSessions: [TrackingSession] = []
    
    // Inverse for default activity relationship
    @Relationship(deleteRule: .nullify, inverse: \NFCTag.defaultActivity)
    var tagsWhereDefault: [NFCTag] = []
    
    init(
        id: UUID = UUID(),
        name: String,
        activityDescription: String,
        createdAt: Date = Date(),
        user: User? = nil
    ) {
        self.id = id
        self.name = name
        self.activityDescription = activityDescription
        self.createdAt = createdAt
        self.user = user
    }
}
