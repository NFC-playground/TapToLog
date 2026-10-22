//
//  TapLogTests.swift
//  TapLogTests
//
//  Created by Sheena Kaw on 10/19/26.
//

import Testing
@testable import TapLog

struct TapLogTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func helloWorld() {
            let greeting = "Hello, world!"
            #expect(greeting == "Hello, world!")
        }

}
