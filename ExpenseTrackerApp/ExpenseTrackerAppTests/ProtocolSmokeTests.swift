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

    func testMockDataServiceTotalBalance() {
        let mockDataService = MockDataService()
        let categoryId = ExpenseTrackerApp.Category.defaultCategories[0].id
        mockDataService.addTransaction(Transaction(amount: -50.0, categoryId: categoryId))
        mockDataService.addTransaction(Transaction(amount: 100.0, categoryId: ExpenseTrackerApp.Category.defaultCategories[10].id))
        let viewModel = DashboardViewModel(dataService: mockDataService)
        XCTAssertEqual(viewModel.totalBalance, 50.0)
    }

    func testMockDataServiceCRUD() {
        let mockDataService = MockDataService()
        let categoryId = ExpenseTrackerApp.Category.defaultCategories[0].id
        let transaction = Transaction(amount: -25.0, categoryId: categoryId)

        // Add
        mockDataService.addTransaction(transaction)
        XCTAssertEqual(mockDataService.transactions.count, 1)

        // Update
        var updated = transaction
        updated.amount = -30.0
        mockDataService.updateTransaction(updated)
        XCTAssertEqual(mockDataService.transactions.first?.amount, -30.0)

        // Delete
        mockDataService.deleteTransaction(transaction)
        XCTAssertTrue(mockDataService.transactions.isEmpty)
    }

    func testMockDataServiceGroupedTransactions() {
        let mockDataService = MockDataService()
        let categoryId = ExpenseTrackerApp.Category.defaultCategories[0].id
        mockDataService.addTransaction(Transaction(amount: -10.0, categoryId: categoryId))
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

    func testMockAuthServiceRegisterSuccess() async {
        let mockAuth = MockAuthService()
        let expectation = XCTestExpectation(description: "Register completes")

        mockAuth.register(email: "test@test.com", password: "password", name: "Test", gender: "Male", phone: "1234567890") { result in
            if case .success(let profile) = result {
                XCTAssertNotNil(profile)
            } else {
                XCTFail("Expected success")
            }
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    func testMockAuthServiceLoginSuccess() async {
        let mockAuth = MockAuthService()
        let expectation = XCTestExpectation(description: "Login completes")

        mockAuth.login(email: "test@test.com", password: "password") { result in
            if case .success = result {
                // Expected
            } else {
                XCTFail("Expected success")
            }
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    func testMockAuthServiceLogout() async {
        let mockAuth = MockAuthService()
        // First login
        let loginExpectation = XCTestExpectation(description: "Login completes")
        mockAuth.login(email: "test@test.com", password: "password") { _ in loginExpectation.fulfill() }
        await fulfillment(of: [loginExpectation], timeout: 2.0)

        // Then logout
        let logoutExpectation = XCTestExpectation(description: "Logout completes")
        mockAuth.logout { result in
            if case .success = result { /* expected */ }
            else { XCTFail("Expected success") }
            logoutExpectation.fulfill()
        }
        await fulfillment(of: [logoutExpectation], timeout: 2.0)
    }

    func testMockAuthServiceRegisterFailure() async {
        let mockAuth = MockAuthService()
        mockAuth.shouldFail = true
        let expectation = XCTestExpectation(description: "Register fails")

        mockAuth.register(email: "test@test.com", password: "password", name: "Test", gender: "Male", phone: "1234567890") { result in
            if case .failure = result {
                // Expected
            } else {
                XCTFail("Expected failure")
            }
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2.0)
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
}
