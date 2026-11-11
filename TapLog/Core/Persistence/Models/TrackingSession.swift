//
//  TrackingSession.swift
//  TapLog
//
//  Created by Sheena Kaw on 10/22/26.
//

import Foundation
import SwiftData


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
