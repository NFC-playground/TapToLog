//
//  AuthView.swift
//  TapLog
//

import SwiftUI
import Supabase

struct AuthView: View {
    @State private var isSignUp = true
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if isSignUp {
                        TextField("Name", text: $name)
                            .textContentType(.name)
                    }
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $password)
                        .textContentType(isSignUp ? .newPassword : .password)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button(isSignUp ? "Create Account" : "Sign In") {
                        Task { await submit() }
                    }
                    .disabled(!canSubmit)
                }

                Section {
                    Button(isSignUp ? "Already have an account? Sign in"
                                    : "Don't have an account? Sign up") {
                        isSignUp.toggle()
                        errorMessage = nil
                    }
                    .font(.footnote)
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle(isSignUp ? "Create Account" : "Sign In")
        }
    }

    // Button is only enabled when the needed fields are filled in
    private var canSubmit: Bool {
        if isLoading || email.isEmpty || password.isEmpty { return false }
        if isSignUp && name.isEmpty { return false }
        return true
    }

    private func submit() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if isSignUp {
                try await supabase.auth.signUp(
                    email: email,
                    password: password,
                    data: ["full_name": .string(name)]
                )
            } else {
                try await supabase.auth.signIn(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    AuthView()
}
