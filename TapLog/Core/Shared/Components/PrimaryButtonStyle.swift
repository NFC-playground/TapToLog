//
//  PrimaryButtonStyle.swift
//  TapLog
//

import SwiftUI

/// Full-width filled button used for the main action on a screen.
/// Turns gray automatically when the button is `.disabled(...)`,
/// and swaps the label for a spinner while `isLoading` is true.
struct PrimaryButtonStyle: ButtonStyle {
    var isLoading = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            // Keep the label in the layout (just hidden) so the button doesn't change height.
            configuration.label.opacity(isLoading ? 0 : 1)
            if isLoading {
                ProgressView().tint(.white)
            }
        }
        .fontWeight(.semibold)
        .frame(maxWidth: .infinity)
        .padding()
        .background(isEnabled ? Color.blue : Color.gray)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    /// `.buttonStyle(.primary)` or `.buttonStyle(.primary(isLoading: true))`
    static var primary: PrimaryButtonStyle { .init() }
    static func primary(isLoading: Bool) -> PrimaryButtonStyle { .init(isLoading: isLoading) }
}

#Preview {
    VStack(spacing: 16) {
        Button("Enabled") {}.buttonStyle(.primary)
        Button("Disabled") {}.buttonStyle(.primary).disabled(true)
        Button("Loading") {}.buttonStyle(.primary(isLoading: true))
    }
    .padding()
}
