//
//  LoginView.swift
//  TapLog
//
//  Created by Sheena Kaw on 11/4/26.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    @State private var showingForgotPassword = false
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Logo/Header
                VStack(spacing: 8) {
                    Image(systemName: "timer.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)
                    
                    Text("TapLog")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Track your activities with NFC")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 40)
                
                // Email & Password Fields
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .emailInput()

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }
                .textFieldStyle(.rounded)
                .padding(.horizontal)
                
                // Forgot Password
                Button {
                    showingForgotPassword = true
                } label: {
                    Text("Forgot Password?")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
                .padding(.top, 4)
                
                // Sign In Button
                Button("Sign In") {
                    Task {
                        await signIn()
                    }
                }
                .buttonStyle(.primary(isLoading: authManager.isLoading))
                .disabled(!isFormValid || authManager.isLoading)
                .padding(.horizontal)
                
                Spacer()
                
                // Sign Up Link
                HStack {
                    Text("Don't have an account?")
                        .foregroundStyle(.secondary)
                    
                    Button("Sign Up") {
                        showingSignUp = true
                    }
                    .fontWeight(.semibold)
                }
                .padding(.bottom, 20)
            }
            .padding()
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(authManager.errorMessage ?? "An unknown error occurred")
            }
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView()
            }
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    // MARK: - Actions
    
    private func signIn() async {
        do {
            try await authManager.signIn(email: email, password: password)
        } catch {
            showingError = true
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
