//
//  RunningTimerView.swift
//  TapLog
//
//  Created by Sheena Kaw on 11/13/26.
//

import SwiftUI

struct RunningTimerView: View {
    let activityName: String
    let startedAt: Date
    let isSaving: Bool
    let onStop: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text(activityName)
                .font(.title2)
            Text(startedAt, style: .timer)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()
            
            Button(role: .destructive) {
                onStop()
            } label: {
                if isSaving {
                    ProgressView()
                } else {
                    Text("Stop")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSaving)
        }
    }
}
    
    #Preview {
        RunningTimerView(
            activityName: "Reading",
            startedAt: .now.addingTimeInterval(-754),  // shows ~12:34 already elapsed
            isSaving: false,
            onStop: {}
        )
    }

