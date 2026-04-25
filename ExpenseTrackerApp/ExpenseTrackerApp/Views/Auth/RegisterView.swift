//
//  RegisterView.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 11/04/26.
//

import SwiftUI

struct RegisterView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var fullName: String = ""
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    @State private var showError: Bool = false

    var onLoginTap: (() -> Void)?

    private var isFormValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty
        && email.contains("@")
        && !email.isEmpty
        && phoneNumber.count >= 7
        && password.count >= 6
        && isAlphanumeric(password)
        && password == confirmPassword
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.Layout.spacing) {

                // MARK: - Header
                headerSection

                // MARK: - Full Name Field
                fullNameField

                // MARK: - Birth Date Field
                birthDateField

                // MARK: - Email Field
                emailField

                // MARK: - Phone Number Field
                phoneNumberField

                // MARK: - Password Field
                passwordField

                // MARK: - Confirm Password Field
                confirmPasswordField

                // MARK: - Sign Up Button
                signUpButton

                // MARK: - Login Link
                loginLink

                Spacer(minLength: 20)
            }
            .padding(.horizontal, Constants.Layout.padding)
            .padding(.top, 20)
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Login") {
                    onLoginTap?()
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.appPrimary)
            }
        }
        .onChange(of: authViewModel.error) { _, newValue in
            showError = newValue != nil
        }
        .alert(
            "Error",
            isPresented: $showError,
            actions: {
                Button("OK") { authViewModel.clearError() }
            },
            message: {
                Text(authViewModel.error?.localizedDescription ?? "")
            }
        )
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Create Account")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.appTextPrimary)

            Text("Sign up to start tracking your expenses")
                .font(.system(size: 15))
                .foregroundStyle(Color.appTextSecondary)
        }
        .padding(.bottom, 16)
    }

    // MARK: - Full Name Field
    private var fullNameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Full Name")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.appTextSecondary)

            HStack(spacing: 12) {
                Image(systemName: "person")
                    .foregroundStyle(Color.appTextTertiary)
                    .frame(width: 20)

                TextField("Enter your full name", text: $fullName)
                    .font(.system(size: 15))
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)
            }
            .padding(16)
            .background(Color.appCardBackground)
            .clipShape(.rect(cornerRadius: Constants.Layout.cardCornerRadius))
        }
    }

    // MARK: - Birth Date Field
    private var birthDateField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Birth Date")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.appTextSecondary)

            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .foregroundStyle(Color.appTextTertiary)
                    .frame(width: 20)

                DatePicker("", selection: $birthDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()

                Spacer()
            }
            .padding(16)
            .background(Color.appCardBackground)
            .clipShape(.rect(cornerRadius: Constants.Layout.cardCornerRadius))
        }
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

    // MARK: - Phone Number Field
    private var phoneNumberField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Phone Number")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.appTextSecondary)

            HStack(spacing: 12) {
                Image(systemName: "phone")
                    .foregroundStyle(Color.appTextTertiary)
                    .frame(width: 20)

                TextField("Enter your phone number", text: $phoneNumber)
                    .font(.system(size: 15))
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
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
                    TextField("Min 6 characters, letters + numbers", text: $password)
                        .font(.system(size: 15))
                        .textContentType(.newPassword)
                } else {
                    SecureField("Min 6 characters, letters + numbers", text: $password)
                        .font(.system(size: 15))
                        .textContentType(.newPassword)
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

    // MARK: - Confirm Password Field
    private var confirmPasswordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Confirm Password")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.appTextSecondary)

            HStack(spacing: 12) {
                Image(systemName: "lock.rotation")
                    .foregroundStyle(Color.appTextTertiary)
                    .frame(width: 20)

                if showConfirmPassword {
                    TextField("Re-enter password", text: $confirmPassword)
                        .font(.system(size: 15))
                        .textContentType(.newPassword)
                } else {
                    SecureField("Re-enter password", text: $confirmPassword)
                        .font(.system(size: 15))
                        .textContentType(.newPassword)
                }

                Button(action: { showConfirmPassword.toggle() }) {
                    Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                        .foregroundStyle(Color.appTextTertiary)
                }
            }
            .padding(16)
            .background(Color.appCardBackground)
            .clipShape(.rect(cornerRadius: Constants.Layout.cardCornerRadius))

            if !confirmPassword.isEmpty && password != confirmPassword {
                Text("Passwords do not match")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appDanger)
            }
        }
    }

    // MARK: - Sign Up Button
    private var signUpButton: some View {
        Button(action: {
            authViewModel.register(
                email: email,
                password: password,
                name: fullName,
                birthDate: birthDate,
                phone: phoneNumber
            )
        }) {
            HStack(spacing: 8) {
                if authViewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                }

                Text(authViewModel.isLoading ? "Creating Account..." : "Sign Up")
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

    // MARK: - Login Link
    private var loginLink: some View {
        HStack(spacing: 4) {
            Text("Already have an account?")
                .font(.system(size: 14))
                .foregroundStyle(Color.appTextSecondary)

            Button(action: { onLoginTap?() }) {
                Text("Login")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.appPrimary)
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Helpers
    private func isAlphanumeric(_ string: String) -> Bool {
        let hasLetter = string.unicodeScalars.contains { CharacterSet.letters.contains($0) }
        let hasDigit = string.unicodeScalars.contains { CharacterSet.decimalDigits.contains($0) }
        return hasLetter && hasDigit
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        RegisterView(authViewModel: AuthViewModel(authService: MockAuthService()))
    }
}
