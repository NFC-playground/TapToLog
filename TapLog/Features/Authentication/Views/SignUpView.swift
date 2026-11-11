//
//  SignUpView.swift
//  TapLog
//
//  Created by Sheena Kaw on 11/4/26.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingError = false
    @State private var showingConfirmEmail = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        TextField("Full Name", text: $name)
                            .textContentType(.name)

                        TextField("Email", text: $email)
                            .emailInput()

                        SecureField("Password", text: $password)
                            .textContentType(.newPassword)

                        SecureField("Confirm Password", text: $confirmPassword)
                            .textContentType(.newPassword)
                    }
                    .textFieldStyle(.rounded)

                    Text("Password must be at least 6 characters")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button("Create Account") {
                        Task {
                            await signUp()
                        }
                    }
                    .buttonStyle(.primary(isLoading: authManager.isLoading))
                    .disabled(!isFormValid || authManager.isLoading)
                }
                .padding()
                .padding(.top, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Check Your Email", isPresented: $showingConfirmEmail) {
                Button("OK") { dismiss() }
            } message: {
                Text("We sent a confirmation link to \(email). Confirm your email, then sign in.")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(authManager.errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        password.count >= 6 &&
        password == confirmPassword
    }
    
    // MARK: - Actions
    
    private func signUp() async {
        do {
            switch try await authManager.signUp(email: email, password: password, name: name) {
            case .signedIn:
                dismiss()
            case .needsEmailConfirmation:
                showingConfirmEmail = true
            }
        } catch {
            showingError = true
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthManager())
}
