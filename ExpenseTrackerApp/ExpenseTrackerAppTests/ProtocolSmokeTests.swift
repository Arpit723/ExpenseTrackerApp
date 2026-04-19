//
//  ProtocolSmokeTests.swift
//  ExpenseTrackerAppTests
//
//  Created by Arpit Parekh on 05/04/26.
//

import XCTest
@testable import ExpenseTrackerApp

@MainActor
final class ProtocolSmokeTests: XCTestCase {

    // MARK: - MockDataService Tests

    func testMockDataServiceCanCreateDashboardViewModel() {
        let mockDataService = MockDataService()
        let viewModel = DashboardViewModel(dataService: mockDataService)
        XCTAssertEqual(viewModel.totalBalance, 0)
    }

    func testMockDataServiceTotalBalance() async throws {
        let mockDataService = MockDataService()
        let categoryId = ExpenseTrackerApp.Category.defaultCategories[0].id
        try await mockDataService.addTransaction(Transaction(amount: -50.0, categoryId: categoryId))
        try await mockDataService.addTransaction(Transaction(amount: 100.0, categoryId: ExpenseTrackerApp.Category.defaultCategories[10].id))
        let viewModel = DashboardViewModel(dataService: mockDataService)
        XCTAssertEqual(viewModel.totalBalance, 50.0)
    }

    func testMockDataServiceCRUD() async throws {
        let mockDataService = MockDataService()
        let categoryId = ExpenseTrackerApp.Category.defaultCategories[0].id
        let transaction = Transaction(amount: -25.0, categoryId: categoryId)

        // Add
        try await mockDataService.addTransaction(transaction)
        XCTAssertEqual(mockDataService.transactions.count, 1)

        // Update
        var updated = transaction
        updated.amount = -30.0
        try await mockDataService.updateTransaction(updated)
        XCTAssertEqual(mockDataService.transactions.first?.amount, -30.0)

        // Delete
        try await mockDataService.deleteTransaction(transaction)
        XCTAssertTrue(mockDataService.transactions.isEmpty)
    }

    func testMockDataServiceGroupedTransactions() async throws {
        let mockDataService = MockDataService()
        let categoryId = ExpenseTrackerApp.Category.defaultCategories[0].id
        try await mockDataService.addTransaction(Transaction(amount: -10.0, categoryId: categoryId))
        let grouped = mockDataService.groupedTransactions()
        XCTAssertFalse(grouped.isEmpty)
    }

    func testMockDataServiceCategoryLookup() {
        let mockDataService = MockDataService()
        let category = mockDataService.categories[0]
        let found = mockDataService.category(for: category.id)
        XCTAssertEqual(found?.name, category.name)
    }

    // MARK: - MockAuthService Tests

    func testMockAuthServiceInitialState() {
        let mockAuth = MockAuthService()
        XCTAssertEqual(mockAuth.authState, .unauthenticated)
    }

    func testMockAuthServiceRegisterSuccess() async throws {
        let mockAuth = MockAuthService()
        let profile = try await mockAuth.register(email: "test@test.com", password: "password", name: "Test", birthDate: Date(), phone: "1234567890")
        XCTAssertNotNil(profile)
        XCTAssertEqual(mockAuth.authState, .authenticated(profile))
    }

    func testMockAuthServiceLoginSuccess() async throws {
        let mockAuth = MockAuthService()
        let profile = try await mockAuth.login(email: "test@test.com", password: "password")
        XCTAssertEqual(mockAuth.authState, .authenticated(profile))
    }

    func testMockAuthServiceLogout() async throws {
        let mockAuth = MockAuthService()
        // First login
        _ = try await mockAuth.login(email: "test@test.com", password: "password")
        // Then logout
        try await mockAuth.logout()
        XCTAssertEqual(mockAuth.authState, .unauthenticated)
    }

    func testMockAuthServiceRegisterFailure() async {
        let mockAuth = MockAuthService()
        mockAuth.shouldFail = true
        do {
            _ = try await mockAuth.register(email: "test@test.com", password: "password", name: "Test", birthDate: Date(), phone: "1234567890")
            XCTFail("Should have thrown")
        } catch {
            // Expected
        }
    }

    func testMockAuthServiceStateListener() {
        let mockAuth = MockAuthService()
        var receivedStates: [AuthState] = []
        mockAuth.addAuthStateListener { state in
            receivedStates.append(state)
        }
        XCTAssertEqual(receivedStates.count, 1)
        XCTAssertEqual(receivedStates.first, .unauthenticated)
        mockAuth.removeAuthStateListener()
    }

    func testMockAuthServiceDeleteAccount() async throws {
        let mockAuth = MockAuthService()
        _ = try await mockAuth.login(email: "test@test.com", password: "password")
        try await mockAuth.deleteAccount()
        XCTAssertEqual(mockAuth.authState, .unauthenticated)
    }

    func testMockAuthServiceResetPassword() async throws {
        let mockAuth = MockAuthService()
        try await mockAuth.resetPassword(email: "test@test.com")
        // Should not throw
    }

    func testMockAuthServiceResetPasswordFailure() async {
        let mockAuth = MockAuthService()
        mockAuth.shouldFail = true
        do {
            try await mockAuth.resetPassword(email: "test@test.com")
            XCTFail("Should have thrown")
        } catch {
            // Expected
        }
    }
}
