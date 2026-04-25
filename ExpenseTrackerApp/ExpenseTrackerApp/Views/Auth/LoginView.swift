//
//  LoginView.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 11/04/26.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var showForgotPassword: Bool = false

    var onSignUpTap: (() -> Void)?

    private var isFormValid: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        return !trimmedEmail.isEmpty
            && trimmedEmail.contains("@")
            && !password.isEmpty
            && password.count >= 6
            && isAlphanumeric(password)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.Layout.spacing) {

                // MARK: - Header
                headerSection

                // MARK: - Email Field
                emailField

                // MARK: - Password Field
                passwordField

                // MARK: - Forgot Password
                forgotPasswordButton

                // MARK: - Login Button
                loginButton

                // MARK: - Sign Up Link
                signUpLink

                Spacer(minLength: 20)
            }
            .padding(.horizontal, Constants.Layout.padding)
            .padding(.top, 40)
        }
        .background(Color.appBackground)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .alert(
            "Error",
            isPresented: errorAlert,
            actions: {
                Button("OK") { authViewModel.clearError() }
            },
            message: {
                Text(authViewModel.error?.localizedDescription ?? "")
            }
        )
        .sheet(isPresented: $showForgotPassword) {
            forgotPasswordSheet
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.appPrimary, Color.appSecondary]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(.white)
            }

            Text("Expense Tracker")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.appTextPrimary)

            Text("Sign in to manage your finances")
                .font(.system(size: 15))
                .foregroundStyle(Color.appTextSecondary)
        }
        .padding(.bottom, 32)
    }

    // MARK: - Email Field
    private var emailField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.appTextSecondary)

            HStack(spacing: 12) {
                Image(systemName: "envelope")
                    .foregroundStyle(Color.appTextTertiary)
                    .frame(width: 20)

                TextField("Enter your email", text: $email)
                    .font(.system(size: 15))
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
            }
            .padding(16)
            .background(Color.appCardBackground)
            .clipShape(.rect(cornerRadius: Constants.Layout.cardCornerRadius))
        }
    }

    // MARK: - Password Field
    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Password")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.appTextSecondary)

            HStack(spacing: 12) {
                Image(systemName: "lock")
                    .foregroundStyle(Color.appTextTertiary)
                    .frame(width: 20)

                if showPassword {
                    TextField("Enter your password", text: $password)
                        .font(.system(size: 15))
                        .textContentType(.password)
                } else {
                    SecureField("Enter your password", text: $password)
                        .font(.system(size: 15))
                        .textContentType(.password)
                }

                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundStyle(Color.appTextTertiary)
                }
            }
            .padding(16)
            .background(Color.appCardBackground)
            .clipShape(.rect(cornerRadius: Constants.Layout.cardCornerRadius))
        }
    }

    // MARK: - Forgot Password
    private var forgotPasswordButton: some View {
        Button(action: {
            showForgotPassword = true
        }) {
            Text("Forgot Password?")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.appPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Login Button
    private var loginButton: some View {
        Button(action: {
            authViewModel.login(email: email, password: password)
        }) {
            HStack(spacing: 8) {
                if authViewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                }

                Text(authViewModel.isLoading ? "Signing In..." : "Login")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: isFormValid
                        ? [Color.appPrimary, Color.appSecondary]
                        : [Color.gray, Color.gray]
                    ),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(.rect(cornerRadius: Constants.Layout.cardCornerRadius))
        }
        .disabled(!isFormValid || authViewModel.isLoading)
        .padding(.top, 8)
    }

    // MARK: - Sign Up Link
    private var signUpLink: some View {
        HStack(spacing: 4) {
            Text("Don't have an account?")
                .font(.system(size: 14))
                .foregroundStyle(Color.appTextSecondary)

            Button(action: { onSignUpTap?() }) {
                Text("Sign Up")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.appPrimary)
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Forgot Password Sheet
    private var forgotPasswordSheet: some View {
        NavigationStack {
            VStack(spacing: Constants.Layout.spacing) {
                Text("Enter your email address and we'll send you a link to reset your password.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 12) {
                    Image(systemName: "envelope")
                        .foregroundStyle(Color.appTextTertiary)
                        .frame(width: 20)

                    TextField("Enter your email", text: $email)
                        .font(.system(size: 15))
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                .padding(16)
                .background(Color.appCardBackground)
                .clipShape(.rect(cornerRadius: Constants.Layout.cardCornerRadius))

                Button(action: {
                    authViewModel.resetPassword(email: email)
                    showForgotPassword = false
                }) {
                    Text("Send Reset Link")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.appPrimary, Color.appSecondary]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(.rect(cornerRadius: Constants.Layout.cardCornerRadius))
                }
                .disabled(email.trimmingCharacters(in: .whitespaces).isEmpty || !email.contains("@"))

                Spacer()
            }
            .padding(.horizontal, Constants.Layout.padding)
            .padding(.top, 20)
            .background(Color.appBackground)
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { showForgotPassword = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Helpers
    private var errorAlert: Binding<Bool> {
        Binding<Bool>(
            get: { authViewModel.error != nil },
            set: { if !$0 { authViewModel.clearError() } }
        )
    }

    private func isAlphanumeric(_ string: String) -> Bool {
        let hasLetter = string.unicodeScalars.contains { CharacterSet.letters.contains($0) }
        let hasDigit = string.unicodeScalars.contains { CharacterSet.decimalDigits.contains($0) }
        return hasLetter && hasDigit
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        LoginView(authViewModel: AuthViewModel(authService: LocalAuthService()))
    }
}
