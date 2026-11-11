//
//  RoundedFieldStyle.swift
//  TapLog
//

import SwiftUI

/// Gray rounded background for text fields. Works for both `TextField` and `SecureField`.
/// Apply it to a container to style every field inside: `.textFieldStyle(.rounded)`.
struct RoundedFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

extension TextFieldStyle where Self == RoundedFieldStyle {
    static var rounded: RoundedFieldStyle { .init() }
}

#Preview {
    VStack(spacing: 16) {
        TextField("Email", text: .constant(""))
        SecureField("Password", text: .constant(""))
    }
    .textFieldStyle(.rounded)
    .padding()
}
