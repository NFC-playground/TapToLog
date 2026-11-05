//
//  RootView.swift
//  TapLog
//
//  Created by Sheena Kaw on 10/26/26.
//

import SwiftUI
import Supabase

struct RootView: View {
    @State private var isSignedIn = false
    @State private var isChecking = true

    //
    var body: some View {
        Group {
            if isChecking {
                ProgressView()
            } else if isSignedIn {
                ContentView()
            } else {
                AuthView()
            }
        }
        .task {
            for await (_, session) in supabase.auth.authStateChanges {
                isSignedIn = (session != nil)
                isChecking = false
            }
        }
    }
}
