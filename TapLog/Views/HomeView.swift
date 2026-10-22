//
//  HomeView.swift
//  TapLog
//
//  Created by Elissa Alarmani on 10/21/26.
//

import SwiftUI

struct HomeView: View {
    // Temporary: replaced by the real active session once SwiftData lands.
    @State private var startedAt: Date? = nil

    var body: some View {
        NavigationStack {
            Group {
                if let startedAt {
                    runningView(startedAt: startedAt)
                } else {
                    idleView
                }
            }
            .navigationTitle("Home")
        }
    }

    private var idleView: some View {
        VStack(spacing: 16) {
            Text("No active timer")
                .font(.headline)
            Text("Tap your NFC to start")
                .foregroundStyle(.secondary)
            Button("Start (test)") {
                startedAt = .now
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func runningView(startedAt: Date) -> some View {
        VStack(spacing: 24) {
            Text("Reading")
                .font(.title2)
            Text(startedAt, style: .timer)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()
            Button("Stop", role: .destructive) {
                self.startedAt = nil
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    HomeView()
}
