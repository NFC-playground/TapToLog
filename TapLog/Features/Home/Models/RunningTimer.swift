//
//  RunningTimer.swift
//  TapLog
//
//  Created by Sheena Kaw on 11/13/26.
//

import Foundation

//Equatable is a Swift protocol that lets you compare two values with == and !=
//2 RunningTimers are equal when all three fields match.

struct RunningTimer: Equatable {
    let activityId: UUID
    let userId: UUID
    let startedAt: Date
}
