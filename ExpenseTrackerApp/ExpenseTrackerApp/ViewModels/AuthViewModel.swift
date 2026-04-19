//
//  AuthViewModel.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 19/04/26.
//

import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var authState: AuthState = .loading
    @Published var error: AppError?
    @Published var isLoading: Bool = false

    // MARK: - Dependencies
    private let authService: any AuthServiceProtocol

    // MARK: - Computed Properties
    var isAuthenticated: Bool {
        if case .authenticated = authState { return true }
        return false
    }

    var currentUser: UserProfile? {
        if case .authenticated(let profile) = authState { return profile }
        return nil
    }

    // MARK: - Initialization
    init(authService: any AuthServiceProtocol) {
        self.authService = authService
        setupAuthListener()
    }

    // MARK: - Setup
    private func setupAuthListener() {
        authService.addAuthStateListener { [weak self] state in
            self?.authState = state
            self?.isLoading = false
        }
    }

    // MARK: - Login
    func login(email: String, password: String) {
        guard validateLogin(email: email, password: password) else { return }

        isLoading = true
        error = nil

        Task {
            do {
                let profile = try await authService.login(email: email, password: password)
                authState = .authenticated(profile)
            } catch let err as AppError {
                self.error = err
                isLoading = false
            } catch {
                self.error = .network(.serverError(error.localizedDescription))
                isLoading = false
            }
        }
    }

    // MARK: - Register
    func register(email: String, password: String, name: String, birthDate: Date, phone: String) {
        guard validateRegister(email: email, password: password, name: name, phone: phone) else { return }

        isLoading = true
        error = nil

        Task {
            do {
                let profile = try await authService.register(
                    email: email,
                    password: password,
                    name: name,
                    birthDate: birthDate,
                    phone: phone
                )
                authState = .authenticated(profile)
            } catch let err as AppError {
                self.error = err
                isLoading = false
            } catch {
                self.error = .network(.serverError(error.localizedDescription))
                isLoading = false
            }
        }
    }

    // MARK: - Logout
    func logout() {
        isLoading = true
        error = nil

        Task {
            do {
                try await authService.logout()
                authState = .unauthenticated
            } catch let err as AppError {
                self.error = err
                isLoading = false
            } catch {
                self.error = .network(.serverError(error.localizedDescription))
                isLoading = false
            }
        }
    }

    // MARK: - Delete Account
    func deleteAccount() {
        isLoading = true
        error = nil

        Task {
            do {
                try await authService.deleteAccount()
                authState = .unauthenticated
            } catch let err as AppError {
                self.error = err
                isLoading = false
            } catch {
                self.error = .network(.serverError(error.localizedDescription))
                isLoading = false
            }
        }
    }

    // MARK: - Reset Password
    func resetPassword(email: String) {
        isLoading = true
        error = nil

        Task {
            do {
                try await authService.resetPassword(email: email)
                isLoading = false
            } catch let err as AppError {
                self.error = err
                isLoading = false
            } catch {
                self.error = .network(.serverError(error.localizedDescription))
                isLoading = false
            }
        }
    }

    // MARK: - Validation
    private func validateLogin(email: String, password: String) -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty else {
            error = .validation(.emptyField("email"))
            return false
        }
        guard trimmedEmail.contains("@") else {
            error = .validation(.invalidEmail)
            return false
        }
        guard !password.isEmpty else {
            error = .validation(.emptyField("password"))
            return false
        }
        guard password.count >= 6 else {
            error = .validation(.invalidPassword)
            return false
        }
        guard isAlphanumeric(password) else {
            error = .validation(.invalidPassword)
            return false
        }
        return true
    }

    private func validateRegister(email: String, password: String, name: String, phone: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            error = .validation(.emptyField("name"))
            return false
        }
        guard !email.isEmpty, email.contains("@") else {
            error = .validation(.invalidEmail)
            return false
        }
        guard phone.count >= 7 else {
            error = .validation(.invalidPhone)
            return false
        }
        guard password.count >= 6 else {
            error = .validation(.invalidPassword)
            return false
        }
        guard isAlphanumeric(password) else {
            error = .validation(.invalidPassword)
            return false
        }
        return true
    }

    private func isAlphanumeric(_ string: String) -> Bool {
        let hasLetter = string.unicodeScalars.contains { CharacterSet.letters.contains($0) }
        let hasDigit = string.unicodeScalars.contains { CharacterSet.decimalDigits.contains($0) }
        return hasLetter && hasDigit
    }

    // MARK: - Error Clearing
    func clearError() {
        error = nil
    }
}
