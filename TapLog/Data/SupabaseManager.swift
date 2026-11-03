//
//  SupabaseManager.swift
//  TapLog
//
//  Created by Sheena Kaw on 10/25/26.
//

import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: Secrets.supabaseURL)!,
    supabaseKey: Secrets.supabaseKey
)
