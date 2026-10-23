//
//  Models.swift
//  TapLog
//
//  Created by Sheena Kaw on 10/21/26.
//

import Foundation
import SwiftData

// MARK: - User Model

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

// MARK: - Activity Model

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

// MARK: - NFC Tag Model

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

// MARK: - NFC Tag Activity Link (Many-to-Many)

@Model
final class NFCTagActivity {
    var id: UUID
    var createdAt: Date
    
    // Relationships
    var tag: NFCTag?
    var activity: Activity?
    
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        tag: NFCTag? = nil,
        activity: Activity? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.tag = tag
        self.activity = activity
    }
}

// MARK: - Tracking Session Model

@Model
final class TrackingSession {
    var id: UUID
    var date: Date
    var duration: TimeInterval // in seconds
    var sessionDescription: String? // Optional description
    
    // Relationships
    var user: User?
    var activity: Activity?
    var nfcTag: NFCTag? // The tag that started this session
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        duration: TimeInterval = 0,
        sessionDescription: String? = nil,
        user: User? = nil,
        activity: Activity? = nil,
        nfcTag: NFCTag? = nil
    ) {
        self.id = id
        self.date = date
        self.duration = duration
        self.sessionDescription = sessionDescription
        self.user = user
        self.activity = activity
        self.nfcTag = nfcTag
    }
}
