//
//  SessionStatsTests.swift
//  TapLogTests
//
//  Created by Elissa Alarmani on 11/11/26.
//

import Testing
import Foundation
@testable import TapLog

struct SessionStatsTests {
    private func session(at date: Date, duration: TimeInterval) -> TrackingSessionDTO {
        TrackingSessionDTO(
            id: UUID(),
            date: date,
            duration: duration,
            sessionDescription: nil,
            userId: nil,
            activityId: nil,
            nfcTagId: nil
        )
    }

    @Test func totalCountsOnlySessionsSinceStart() {
        let start = Date(timeIntervalSince1970: 1_000_000)
        let sessions = [
            session(at: start.addingTimeInterval(-60), duration: 100),   // before start: ignored
            session(at: start, duration: 200),                           // exactly at start: counted
            session(at: start.addingTimeInterval(3600), duration: 300),  // after start: counted
        ]
        #expect(SessionStats.totalDuration(of: sessions, since: start) == 500)
    }

    @Test func totalIsZeroWithNoSessions() {
        #expect(SessionStats.totalDuration(of: [], since: .now) == 0)
    }

    @Test(arguments: zip(
        [0.0, 59, 60, 3600, 5025],
        ["0m", "0m", "1m", "1h 0m", "1h 23m"]
    ))
    func shortFormat(seconds: Double, expected: String) {
        #expect(DurationFormat.short(seconds) == expected)
    }
}
