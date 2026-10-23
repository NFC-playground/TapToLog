//
//  ContentView.swift
//  TapLog
//
//  Created by Sheena Kaw on 10/19/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "timer") {
                HomeView()
            }
            Tab("History", systemImage: "clock.arrow.circlepath") {
                HistoryView()
            }
            Tab("NFC Tags", systemImage: "wave.3.right") {
                TagSetupView()
            }
            Tab("Settings", systemImage: "gear") {
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
}
