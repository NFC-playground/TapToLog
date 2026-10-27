//
//  TapLogApp.swift
//  TapLog
//
//  Created by Sheena Kaw on 10/19/26.
//

import SwiftUI
import SwiftData

@main
struct TapLogApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        //creates database that can be access
        // by using: @Environment(\.modelContext)
        .modelContainer(for: [
            User.self,
            Activity.self,
            NFCTag.self,
            NFCTagActivity.self,
            TrackingSession.self
        ])
    }
}
