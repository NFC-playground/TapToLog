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
            Form {
                Section {
                    TextField("Full Name", text: $name)
                        .textContentType(.name)
                    
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                } header: {
                    Text("Account Information")
                } footer: {
                    Text("Password must be at least 6 characters")
                }
                
                Section {
                    Button {
                        Task {
                            await signUp()
                        }
                    } label: {
                        if authManager.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Create Account")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isFormValid || authManager.isLoading)
                }
            }
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
