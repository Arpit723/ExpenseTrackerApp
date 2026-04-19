//
//  FirebaseAuthServiceTests.swift
//  ExpenseTrackerAppTests
//
//  Created by Arpit Parekh on 19/04/26.
//
//  Requires Firebase Auth Emulator running on localhost:9099
//  Start with: firebase emulators:start
//

import XCTest
import FirebaseAuth
@testable import ExpenseTrackerApp

@MainActor
final class FirebaseAuthServiceTests: XCTestCase {

    private var authService: FirebaseAuthService!

    override func setUp() async throws {
        try await super.setUp()
        // Use Firebase Auth emulator for testing
        Auth.auth().useEmulator(withHost: "localhost", port: 9099)
        authService = FirebaseAuthService()

        // Clear any existing users in the emulator
        // Sign out any current user
        try? Auth.auth().signOut()
    }

    override func tearDown() async throws {
        try? Auth.auth().signOut()
        authService = nil
        try await super.tearDown()
    }

    // MARK: - Register + Login

    func testRegisterAndLogin() async throws {
        let email = "test-\(UUID().uuidString.prefix(8))@test.com"
        let password = "pass123"

        // Register
        let profile = try await authService.register(
            email: email,
            password: password,
            name: "Test User",
            birthDate: Date(),
            phone: "1234567890"
        )

        XCTAssertEqual(profile.email, email)
        XCTAssertEqual(profile.fullName, "Test User")
        XCTAssertNotNil(profile.uid)

        // Sign out first
        try await authService.logout()

        // Login with same credentials
        let loginProfile = try await authService.login(email: email, password: password)
        XCTAssertEqual(loginProfile.email, email)
    }

    func testLoginFailureInvalidCredentials() async throws {
        do {
            _ = try await authService.login(email: "nonexistent@test.com", password: "wrong123")
            XCTFail("Should have thrown")
        } catch {
            // Expected - Firebase Auth returns error for invalid credentials
        }
    }

    // MARK: - Logout

    func testLogout() async throws {
        let email = "logout-\(UUID().uuidString.prefix(8))@test.com"
        _ = try await authService.register(
            email: email,
            password: "pass123",
            name: "Test",
            birthDate: Date(),
            phone: "1234567890"
        )

        try await authService.logout()

        // After logout, auth state should be unauthenticated
        if case .unauthenticated = authService.authState {
            // Success
        } else {
            XCTFail("Expected unauthenticated after logout")
        }
    }

    // MARK: - Reset Password

    func testResetPassword() async throws {
        let email = "reset-\(UUID().uuidString.prefix(8))@test.com"
        _ = try await authService.register(
            email: email,
            password: "pass123",
            name: "Test",
            birthDate: Date(),
            phone: "1234567890"
        )
        try await authService.logout()

        // Should not throw
        try await authService.resetPassword(email: email)
    }

    // MARK: - Auth State Listener

    func testAuthStateListener() async throws {
        let expectation = XCTestExpectation(description: "Auth state listener fires")
        var receivedStates: [AuthState] = []

        authService.addAuthStateListener { state in
            receivedStates.append(state)
            if receivedStates.count >= 1 {
                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertFalse(receivedStates.isEmpty)
    }

    // MARK: - Delete Account

    func testDeleteAccount() async throws {
        let email = "delete-\(UUID().uuidString.prefix(8))@test.com"
        _ = try await authService.register(
            email: email,
            password: "pass123",
            name: "Test",
            birthDate: Date(),
            phone: "1234567890"
        )

        try await authService.deleteAccount()

        if case .unauthenticated = authService.authState {
            // Success
        } else {
            XCTFail("Expected unauthenticated after account deletion")
        }
    }
}
