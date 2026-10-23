//
//  NFCTagActivity.swift
//  TapLog
//
//  Created by Sheena Kaw on 10/22/26.
//
import Foundation
import SwiftData

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
