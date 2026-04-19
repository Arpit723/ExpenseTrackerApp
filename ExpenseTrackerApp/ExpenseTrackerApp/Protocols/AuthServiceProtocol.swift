//
//  AuthServiceProtocol.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 05/04/26.
//

import Foundation
import Combine

// MARK: - Auth State
enum AuthState: Equatable {
    case loading
    case authenticated(UserProfile)
    case unauthenticated
}

// MARK: - Auth Service Protocol
@MainActor
protocol AuthServiceProtocol: ObservableObject {
    var authState: AuthState { get }

    func register(email: String, password: String, name: String, birthDate: Date, phone: String) async throws -> UserProfile
    func login(email: String, password: String) async throws -> UserProfile
    func logout() async throws
    func deleteAccount() async throws
    func resetPassword(email: String) async throws
    func addAuthStateListener(_ listener: @escaping (AuthState) -> Void)
    func removeAuthStateListener()
}

#if DEBUG
// MARK: - Mock Auth Service (Debug Only)
@MainActor
class MockAuthService: ObservableObject, AuthServiceProtocol {
    @Published var authState: AuthState = .unauthenticated

    var shouldFail: Bool = false

    private var authStateListener: ((AuthState) -> Void)?

    func register(email: String, password: String, name: String, birthDate: Date, phone: String) async throws -> UserProfile {
        if shouldFail {
            throw AppError.auth(.invalidCredentials)
        }
        let profile = UserProfile(preferences: UserPreferences())
        authState = .authenticated(profile)
        authStateListener?(authState)
        return profile
    }

    func login(email: String, password: String) async throws -> UserProfile {
        if shouldFail {
            throw AppError.auth(.invalidCredentials)
        }
        let profile = UserProfile(preferences: UserPreferences())
        authState = .authenticated(profile)
        authStateListener?(authState)
        return profile
    }

    func logout() async throws {
        if shouldFail {
            throw AppError.auth(.sessionExpired)
        }
        authState = .unauthenticated
        authStateListener?(authState)
    }

    func deleteAccount() async throws {
        if shouldFail {
            throw AppError.auth(.sessionExpired)
        }
        authState = .unauthenticated
        authStateListener?(authState)
    }

    func resetPassword(email: String) async throws {
        if shouldFail {
            throw AppError.auth(.userNotFound)
        }
    }

    func addAuthStateListener(_ listener: @escaping (AuthState) -> Void) {
        authStateListener = listener
        listener(authState)
    }

    func removeAuthStateListener() {
        authStateListener = nil
    }
}
#endif
