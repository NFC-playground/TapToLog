//
//  ForgotPasswordView.swift
//  TapLog
//
//  Created by Sheena Kaw on 11/4/26.
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @State private var email = ""
    @State private var showingSuccess = false
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "lock.rotation")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                    .padding(.top, 40)
                
                Text("Reset Password")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Enter your email address and we'll send you a link to reset your password.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top, 20)
                
                Button {
                    Task {
                        await resetPassword()
                    }
                } label: {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Text("Send Reset Link")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isEmailValid ? Color.blue : Color.gray)
                .foregroundStyle(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(!isEmailValid || authManager.isLoading)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Success", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Password reset link sent to \(email)")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(authManager.errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    // MARK: - Validation
    
    private var isEmailValid: Bool {
        !email.isEmpty && email.contains("@")
    }
    
    // MARK: - Actions
    
    private func resetPassword() async {
        do {
            try await authManager.resetPassword(email: email)
            showingSuccess = true
        } catch {
            showingError = true
        }
    }
}

#Preview {
    ForgotPasswordView()
        .environmentObject(AuthManager())
}
