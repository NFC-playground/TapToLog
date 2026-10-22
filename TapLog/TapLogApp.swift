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
            ContentView()
        }
        .modelContainer(for: [
            User.self,
            Activity.self,
            NFCTag.self,
            NFCTagActivity.self,
            TrackingSession.self
        ])
    }
}
