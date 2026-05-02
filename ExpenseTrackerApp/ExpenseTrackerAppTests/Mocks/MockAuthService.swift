//
//  MockAuthService.swift
//  ExpenseTrackerAppTests
//
//  Created by Arpit Parekh on 05/04/26.
//

import Foundation
import Combine
@testable import ExpenseTrackerApp

// MARK: - Mock Auth Service
@MainActor
class MockAuthService: ObservableObject, AuthServiceProtocol {
    @Published var authState: AuthState = .unauthenticated

    var shouldFail: Bool = false

    private var authStateListener: ((AuthState) -> Void)?

    // MARK: - Register
    func register(email: String, password: String, name: String, birthDate: Date, phone: String) async throws -> UserProfile {
        if shouldFail {
            throw AppError.auth(.invalidCredentials)
        }
        let profile = UserProfile(preferences: UserPreferences())
        authState = .authenticated(profile)
        authStateListener?(authState)
        return profile
    }

    // MARK: - Login
    func login(email: String, password: String) async throws -> UserProfile {
        if shouldFail {
            throw AppError.auth(.invalidCredentials)
        }
        let profile = UserProfile(preferences: UserPreferences())
        authState = .authenticated(profile)
        authStateListener?(authState)
        return profile
    }

    // MARK: - Logout
    func logout() async throws {
        if shouldFail {
            throw AppError.auth(.sessionExpired)
        }
        authState = .unauthenticated
        authStateListener?(authState)
    }

    // MARK: - Delete Account
    func deleteAccount() async throws {
        if shouldFail {
            throw AppError.auth(.sessionExpired)
        }
        authState = .unauthenticated
        authStateListener?(authState)
    }

    // MARK: - Reset Password
    func resetPassword(email: String) async throws {
        if shouldFail {
            throw AppError.auth(.userNotFound)
        }
    }

    // MARK: - Update Profile
    func updateProfile(name: String, phone: String, birthDate: Date) async throws -> UserProfile {
        if shouldFail {
            throw AppError.data(.saveFailed)
        }
        let updated = UserProfile(
            fullName: name,
            birthDate: birthDate,
            phone: phone,
            preferences: UserPreferences()
        )
        authState = .authenticated(updated)
        authStateListener?(authState)
        return updated
    }

    // MARK: - Send Email Verification
    func sendEmailVerification(email: String, password: String) async throws {
        if shouldFail {
            throw AppError.auth(.userNotFound)
        }
    }

    // MARK: - Auth State Listener
    func addAuthStateListener(_ listener: @escaping (AuthState) -> Void) {
        authStateListener = listener
        listener(authState)
    }

    func removeAuthStateListener() {
        authStateListener = nil
    }
}
