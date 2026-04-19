//
//  LoginView.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 11/04/26.
//

import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var isLoading: Bool = false

    var onSignUpTap: (() -> Void)?
    var onLoginSuccess: (() -> Void)?

    private var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty
        && email.contains("@")
        && !password.isEmpty
        && password.count >= 6
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
            // TODO: Implement forgot password flow
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
            isLoading = true
            // TODO: Implement login with Firebase Auth
            // Static: simulate login success after delay
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                isLoading = false
                onLoginSuccess?()
            }
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }

                Text(isLoading ? "Signing In..." : "Login")
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
        .disabled(!isFormValid || isLoading)
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
}

// MARK: - Preview
#Preview {
    NavigationStack {
        LoginView()
    }
}
