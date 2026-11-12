//
//  SessionStats.swift
//  TapLog
//
//  Created by Elissa Alarmani on 11/11/26.
//

import Foundation

/// Totals for the Home summaries. Kept separate from the view so it's easy to test.
enum SessionStats {
    /// Total seconds of sessions that started on or after `start`.
    static func totalDuration(of sessions: [TrackingSessionDTO], since start: Date) -> TimeInterval {
        sessions
            .filter { $0.date >= start }
            .reduce(0) { $0 + $1.duration }
    }

    static func startOfToday(now: Date = .now, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: now)
    }

    static func startOfWeek(now: Date = .now, calendar: Calendar = .current) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: now)?.start
            ?? calendar.startOfDay(for: now)
    }
}
