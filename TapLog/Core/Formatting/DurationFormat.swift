//
//  DurationFormat.swift
//  TapLog
//
//  Created by Elissa Alarmani on 11/11/26.
//

import Foundation

/// Turns a number of seconds into short text like "1h 23m" or "45m".
enum DurationFormat {
    static func short(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
