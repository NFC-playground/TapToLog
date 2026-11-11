//
//  PreviewContainer.swift
//  TapLog
//
//  Created by Sheena Kaw on 10/25/26.
//
import Foundation
import SwiftData

//previewContainer creates an empty in-memory database with your five models,
// fills it with seed data, and returns it, so previews
// have realistic data to show without touching your real data.

extension SeedData {
    /// Creates a preview container with seed data
    @MainActor
    static var previewContainer: ModelContainer {
        let schema = Schema([
            User.self,
            Activity.self,
            NFCTag.self,
            NFCTagActivity.self,
            TrackingSession.self
        ])
        
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        
        let container = try! ModelContainer(for: schema, configurations: configuration)
        
        // Generate seed data for preview
        generateSeedData(modelContext: container.mainContext)
        
        return container
    }
}
