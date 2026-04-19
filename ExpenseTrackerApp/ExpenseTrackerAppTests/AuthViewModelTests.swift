//
//  AuthViewModelTests.swift
//  ExpenseTrackerAppTests
//
//  Created by Arpit Parekh on 19/04/26.
//

import XCTest
@testable import ExpenseTrackerApp

@MainActor
final class AuthViewModelTests: XCTestCase {

    private func makeViewModel(shouldFail: Bool = false) -> (AuthViewModel, MockAuthService) {
        let mockAuth = MockAuthService()
        mockAuth.shouldFail = shouldFail
        let viewModel = AuthViewModel(authService: mockAuth)
        return (viewModel, mockAuth)
    }

    // MARK: - Initial State

    func testInitialStateIsSetByListener() {
        let (viewModel, _) = makeViewModel()
        // MockAuthService listener fires with .unauthenticated on init
        XCTAssertEqual(viewModel.authState, .unauthenticated)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }

    // MARK: - Login

    func testLoginSuccess() async throws {
        let (viewModel, _) = makeViewModel()
        viewModel.login(email: "test@test.com", password: "pass123")

        // Wait for async Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        if case .authenticated = viewModel.authState {
            // Success
        } else {
            XCTFail("Expected authenticated state, got \(viewModel.authState)")
        }
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }

    func testLoginFailure() async throws {
        let (viewModel, _) = makeViewModel(shouldFail: true)
        viewModel.login(email: "test@test.com", password: "pass123")

        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoginSetsLoadingDuringRequest() {
        let (viewModel, _) = makeViewModel()
        viewModel.login(email: "test@test.com", password: "pass123")
        // isLoading should be true immediately after calling login
        XCTAssertTrue(viewModel.isLoading)
    }

    func testLoginValidationEmptyEmail() {
        let (viewModel, _) = makeViewModel()
        viewModel.login(email: "", password: "pass123")
        XCTAssertEqual(viewModel.error, .validation(.emptyField("email")))
        XCTAssertTrue(viewModel.isLoading == false)
    }

    func testLoginValidationInvalidEmail() {
        let (viewModel, _) = makeViewModel()
        viewModel.login(email: "notanemail", password: "pass123")
        XCTAssertEqual(viewModel.error, .validation(.invalidEmail))
    }

    func testLoginValidationEmptyPassword() {
        let (viewModel, _) = makeViewModel()
        viewModel.login(email: "test@test.com", password: "")
        XCTAssertEqual(viewModel.error, .validation(.emptyField("password")))
    }

    func testLoginValidationShortPassword() {
        let (viewModel, _) = makeViewModel()
        viewModel.login(email: "test@test.com", password: "ab1")
        XCTAssertEqual(viewModel.error, .validation(.invalidPassword))
    }

    func testLoginValidationNonAlphanumericPassword() {
        let (viewModel, _) = makeViewModel()
        viewModel.login(email: "test@test.com", password: "123456")
        XCTAssertEqual(viewModel.error, .validation(.invalidPassword))
    }

    // MARK: - Register

    func testRegisterSuccess() async throws {
        let (viewModel, _) = makeViewModel()
        viewModel.register(
            email: "test@test.com",
            password: "pass123",
            name: "Test User",
            birthDate: Date(),
            phone: "1234567890"
        )

        try await Task.sleep(nanoseconds: 100_000_000)

        if case .authenticated = viewModel.authState {
            // Success
        } else {
            XCTFail("Expected authenticated state after register")
        }
        XCTAssertNil(viewModel.error)
    }

    func testRegisterFailure() async throws {
        let (viewModel, _) = makeViewModel(shouldFail: true)
        viewModel.register(
            email: "test@test.com",
            password: "pass123",
            name: "Test",
            birthDate: Date(),
            phone: "1234567890"
        )

        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testRegisterValidationEmptyName() {
        let (viewModel, _) = makeViewModel()
        viewModel.register(
            email: "test@test.com",
            password: "pass123",
            name: "  ",
            birthDate: Date(),
            phone: "1234567890"
        )
        XCTAssertEqual(viewModel.error, .validation(.emptyField("name")))
    }

    func testRegisterValidationInvalidEmail() {
        let (viewModel, _) = makeViewModel()
        viewModel.register(
            email: "noemail",
            password: "pass123",
            name: "Test",
            birthDate: Date(),
            phone: "1234567890"
        )
        XCTAssertEqual(viewModel.error, .validation(.invalidEmail))
    }

    func testRegisterValidationShortPhone() {
        let (viewModel, _) = makeViewModel()
        viewModel.register(
            email: "test@test.com",
            password: "pass123",
            name: "Test",
            birthDate: Date(),
            phone: "123"
        )
        XCTAssertEqual(viewModel.error, .validation(.invalidPhone))
    }

    // MARK: - Logout

    func testLogoutSuccess() async throws {
        let (viewModel, _) = makeViewModel()
        // First login
        viewModel.login(email: "test@test.com", password: "pass123")
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then logout
        viewModel.logout()
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(viewModel.authState, .unauthenticated)
        XCTAssertNil(viewModel.error)
    }

    func testLogoutFailure() async throws {
        let (viewModel, _) = makeViewModel(shouldFail: true)
        viewModel.logout()
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(viewModel.error)
    }

    // MARK: - Delete Account

    func testDeleteAccountSuccess() async throws {
        let (viewModel, _) = makeViewModel()
        // Login first
        viewModel.login(email: "test@test.com", password: "pass123")
        try await Task.sleep(nanoseconds: 100_000_000)

        viewModel.deleteAccount()
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(viewModel.authState, .unauthenticated)
        XCTAssertNil(viewModel.error)
    }

    func testDeleteAccountFailure() async throws {
        let (viewModel, _) = makeViewModel(shouldFail: true)
        viewModel.deleteAccount()
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(viewModel.error)
    }

    // MARK: - Reset Password

    func testResetPasswordSuccess() async throws {
        let (viewModel, _) = makeViewModel()
        viewModel.resetPassword(email: "test@test.com")
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testResetPasswordFailure() async throws {
        let (viewModel, _) = makeViewModel(shouldFail: true)
        viewModel.resetPassword(email: "test@test.com")
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(viewModel.error)
    }

    // MARK: - Computed Properties

    func testIsAuthenticated() async throws {
        let (viewModel, _) = makeViewModel()
        XCTAssertFalse(viewModel.isAuthenticated)

        viewModel.login(email: "test@test.com", password: "pass123")
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(viewModel.isAuthenticated)
    }

    func testCurrentUser() async throws {
        let (viewModel, _) = makeViewModel()
        XCTAssertNil(viewModel.currentUser)

        viewModel.login(email: "test@test.com", password: "pass123")
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(viewModel.currentUser)
    }

    // MARK: - Clear Error

    func testClearError() {
        let (viewModel, _) = makeViewModel()
        viewModel.login(email: "", password: "pass123")
        XCTAssertNotNil(viewModel.error)

        viewModel.clearError()
        XCTAssertNil(viewModel.error)
    }
}
