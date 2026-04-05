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
    var delay: TimeInterval = 0

    private var authStateListener: ((AuthState) -> Void)?

    // MARK: - Register
    func register(email: String, password: String, name: String, gender: String, phone: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            if self.shouldFail {
                completion(.failure(NSError(domain: "MockAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Registration failed"])))
            } else {
                let profile = UserProfile(preferences: UserPreferences())
                self.authState = .authenticated(profile)
                self.authStateListener?(self.authState)
                completion(.success(profile))
            }
        }
    }

    // MARK: - Login
    func login(email: String, password: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            if self.shouldFail {
                completion(.failure(NSError(domain: "MockAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Login failed"])))
            } else {
                let profile = UserProfile(preferences: UserPreferences())
                self.authState = .authenticated(profile)
                self.authStateListener?(self.authState)
                completion(.success(profile))
            }
        }
    }

    // MARK: - Logout
    func logout(completion: @escaping (Result<Void, Error>) -> Void) {
        authState = .unauthenticated
        authStateListener?(authState)
        completion(.success(()))
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
