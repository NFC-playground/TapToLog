//
//  SessionStats.swift
//  TapLog
//
//  Created by Elissa Alarmani on 11/11/26.
//

import Foundation

/// Totals for the Home summaries. Kept separate from the view so it's easy to test.
enum SessionStats {
    /// Sessions for one activity, or all sessions when `activityId` is nil.
    static func sessions(
        _ sessions: [TrackingSessionDTO],
        for activityId: UUID?
    ) -> [TrackingSessionDTO] {
        guard let activityId else { return sessions }
        return sessions.filter { $0.activityId == activityId }
    }

    /// Total seconds of sessions that started on or after `start`.
    /// Pass `activityId` to count only that activity; nil counts everything.
    static func totalDuration(
        of sessions: [TrackingSessionDTO],
        since start: Date,
        activityId: UUID? = nil
    ) -> TimeInterval {
        Self.sessions(sessions, for: activityId)
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
