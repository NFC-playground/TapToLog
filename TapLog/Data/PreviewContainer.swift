//
//  PreviewContainer.swift
//  TapLog
//
//  Created by Sheena Kaw on 10/25/26.
//
import Foundation
import SwiftData

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
