//
//  LocalAuthService.swift
//  ExpenseTrackerApp
//
//  Temporary in-memory auth service for development.
//  Replaced by FirebaseAuthService in Phase 2.
//

import Foundation

@MainActor
class LocalAuthService: ObservableObject, AuthServiceProtocol {
    @Published var authState: AuthState = .unauthenticated

    private var authStateListener: ((AuthState) -> Void)?

    func register(email: String, password: String, name: String, birthDate: Date, phone: String) async throws -> UserProfile {
        let profile = UserProfile(preferences: UserPreferences())
        authState = .authenticated(profile)
        authStateListener?(authState)
        return profile
    }

    func login(email: String, password: String) async throws -> UserProfile {
        let profile = UserProfile(preferences: UserPreferences())
        authState = .authenticated(profile)
        authStateListener?(authState)
        return profile
    }

    func logout() async throws {
        authState = .unauthenticated
        authStateListener?(authState)
    }

    func deleteAccount() async throws {
        authState = .unauthenticated
        authStateListener?(authState)
    }

    func resetPassword(email: String) async throws {
        // No-op for local service
    }

    func addAuthStateListener(_ listener: @escaping (AuthState) -> Void) {
        authStateListener = listener
        listener(authState)
    }

    func removeAuthStateListener() {
        authStateListener = nil
    }
}
