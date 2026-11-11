//
//  View+EmailInput.swift
//  TapLog
//

import SwiftUI

extension View {
    /// Keyboard and autofill settings for an email address field.
    func emailInput() -> some View {
        self
            .textContentType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(.emailAddress)
    }
}
