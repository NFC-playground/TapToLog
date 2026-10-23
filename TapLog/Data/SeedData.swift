//
//  SeedData.swift
//  TapLog
//
//  Created for seeding test data
//

import Foundation
import SwiftData

@MainActor
struct SeedData {
    
    /// Generates and inserts seed data into the model context
    static func generateSeedData(modelContext: ModelContext) {
        // Check if data already exists
        let descriptor = FetchDescriptor<User>()
        let existingUsers = (try? modelContext.fetch(descriptor)) ?? []
        
        guard existingUsers.isEmpty else {
            print("Seed data already exists. Skipping generation.")
            return
        }
        
        print("Generating seed data...")
        
        // Create users
        let sheena = User(name: "Sheena", createdAt: Date())
        let elissa = User(name: "Elissa", createdAt: Date())
        
        modelContext.insert(sheena)
        modelContext.insert(elissa)
        
        // Create activities for Sheena
        let reading = Activity(
            name: "Reading",
            activityDescription: "reading",
            createdAt: Date(),
            user: sheena
        )
        
        let programming = Activity(
            name: "Programming",
            activityDescription: "programming",
            createdAt: Date(),
            user: sheena
        )
        
        let writing = Activity(
            name: "Writing",
            activityDescription: "writing",
            createdAt: Date(),
            user: sheena
        )
        
        modelContext.insert(reading)
        modelContext.insert(programming)
        modelContext.insert(writing)
        
        // Create activities for Elissa
        let coding = Activity(
            name: "Coding",
            activityDescription: "programming",
            createdAt: Date(),
            user: elissa
        )
        
        let studying = Activity(
            name: "Studying",
            activityDescription: "reading",
            createdAt: Date(),
            user: elissa
        )
        
        modelContext.insert(coding)
        modelContext.insert(studying)
        
        // Create NFC tags for Sheena
        let deskTag = NFCTag(
            tagIdentifier: "NFC-DESK-001",
            name: "Desk Tag",
            createdAt: Date(),
            owner: sheena,
            defaultActivity: programming
        )
        
        let couchTag = NFCTag(
            tagIdentifier: "NFC-COUCH-001",
            name: "Couch Tag",
            createdAt: Date(),
            owner: sheena,
            defaultActivity: reading
        )
        
        modelContext.insert(deskTag)
        modelContext.insert(couchTag)
        
        // Create NFC tag for Elissa
        let officeTag = NFCTag(
            tagIdentifier: "NFC-OFFICE-001",
            name: "Office Tag",
            createdAt: Date(),
            owner: elissa,
            defaultActivity: coding
        )
        
        modelContext.insert(officeTag)
        
        // Link activities to desk tag
        let deskProgramming = NFCTagActivity(
            createdAt: Date(),
            tag: deskTag,
            activity: programming
        )
        
        let deskWriting = NFCTagActivity(
            createdAt: Date(),
            tag: deskTag,
            activity: writing
        )
        
        modelContext.insert(deskProgramming)
        modelContext.insert(deskWriting)
        
        // Link activities to couch tag
        let couchReading = NFCTagActivity(
            createdAt: Date(),
            tag: couchTag,
            activity: reading
        )
        
        modelContext.insert(couchReading)
        
        // Link activities to office tag
        let officeCoding = NFCTagActivity(
            createdAt: Date(),
            tag: officeTag,
            activity: coding
        )
        
        let officeStudying = NFCTagActivity(
            createdAt: Date(),
            tag: officeTag,
            activity: studying
        )
        
        modelContext.insert(officeCoding)
        modelContext.insert(officeStudying)
        
        // Create some tracking sessions for the past week
        let calendar = Calendar.current
        let now = Date()
        
        // Sheena's sessions
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            
            // Morning programming session
            let morningSession = TrackingSession(
                date: date.addingTimeInterval(-8 * 3600), // 8 hours ago
                duration: Double.random(in: 1800...7200), // 30min to 2hrs
                sessionDescription: "Morning coding session",
                user: sheena,
                activity: programming,
                nfcTag: deskTag
            )
            modelContext.insert(morningSession)
            
            // Evening reading session
            let eveningSession = TrackingSession(
                date: date.addingTimeInterval(-2 * 3600), // 2 hours ago
                duration: Double.random(in: 1200...3600), // 20min to 1hr
                sessionDescription: "Evening reading",
                user: sheena,
                activity: reading,
                nfcTag: couchTag
            )
            modelContext.insert(eveningSession)
        }
        
        // Elissa's sessions
        for dayOffset in 0..<5 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            
            let codingSession = TrackingSession(
                date: date.addingTimeInterval(-6 * 3600),
                duration: Double.random(in: 3600...10800), // 1hr to 3hrs
                sessionDescription: "Work session",
                user: elissa,
                activity: coding,
                nfcTag: officeTag
            )
            modelContext.insert(codingSession)
        }
        
        // Save all changes
        do {
            try modelContext.save()
            print("✅ Seed data generated successfully!")
            print("   - 2 Users")
            print("   - 5 Activities")
            print("   - 3 NFC Tags")
            print("   - 5 Tag-Activity Links")
            print("   - \(14 + 5) Tracking Sessions")
        } catch {
            print("❌ Failed to save seed data: \(error)")
        }
    }
    
    /// Deletes all data from the model context
    static func clearAllData(modelContext: ModelContext) {
        print("Clearing all data...")
        
        do {
            // Delete in order to respect relationships
            try modelContext.delete(model: TrackingSession.self)
            try modelContext.delete(model: NFCTagActivity.self)
            try modelContext.delete(model: NFCTag.self)
            try modelContext.delete(model: Activity.self)
            try modelContext.delete(model: User.self)
            
            try modelContext.save()
            print("✅ All data cleared successfully!")
        } catch {
            print("❌ Failed to clear data: \(error)")
        }
    }
}

// MARK: - Preview Helper

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
