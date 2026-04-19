//
//  DashboardViewModelTests.swift
//  ExpenseTrackerAppTests
//
//  Created by Arpit Parekh on 19/04/26.
//

import XCTest
@testable import ExpenseTrackerApp

@MainActor
final class DashboardViewModelTests: XCTestCase {

    private func makeViewModel() -> (DashboardViewModel, MockDataService) {
        let mockData = MockDataService()
        let viewModel = DashboardViewModel(dataService: mockData)
        return (viewModel, mockData)
    }

    // MARK: - Today's Spending

    func testTodaySpendingWithNoTransactions() {
        let (viewModel, _) = makeViewModel()
        XCTAssertEqual(viewModel.todaySpending, 0)
    }

    func testTodaySpendingWithTodayExpense() async throws {
        let (viewModel, mockData) = makeViewModel()
        let categoryId = mockData.categories[0].id
        try await mockData.addTransaction(Transaction(amount: -25.0, categoryId: categoryId))
        viewModel.refreshData()

        XCTAssertEqual(viewModel.todaySpending, 25.0)
    }

    func testTodaySpendingIgnoresIncome() async throws {
        let (viewModel, mockData) = makeViewModel()
        let categoryId = mockData.categories[10].id
        try await mockData.addTransaction(Transaction(amount: 100.0, categoryId: categoryId))
        viewModel.refreshData()

        XCTAssertEqual(viewModel.todaySpending, 0)
    }

    func testTodaySpendingMultipleExpenses() async throws {
        let (viewModel, mockData) = makeViewModel()
        let cat0 = mockData.categories[0].id
        let cat1 = mockData.categories[1].id
        try await mockData.addTransaction(Transaction(amount: -10.0, categoryId: cat0))
        try await mockData.addTransaction(Transaction(amount: -20.0, categoryId: cat1))
        try await mockData.addTransaction(Transaction(amount: 50.0, categoryId: mockData.categories[10].id))
        viewModel.refreshData()

        XCTAssertEqual(viewModel.todaySpending, 30.0)
    }

    // MARK: - Category Spending

    func testCategorySpendingEmpty() {
        let (viewModel, _) = makeViewModel()
        XCTAssertTrue(viewModel.categorySpending.isEmpty)
    }

    func testCategorySpendingSingleCategory() async throws {
        let (viewModel, mockData) = makeViewModel()
        let categoryId = mockData.categories[0].id
        try await mockData.addTransaction(Transaction(amount: -50.0, categoryId: categoryId))
        viewModel.refreshData()

        XCTAssertEqual(viewModel.categorySpending.count, 1)
        XCTAssertEqual(viewModel.categorySpending[0].category.id, categoryId)
        XCTAssertEqual(viewModel.categorySpending[0].amount, 50.0)
        XCTAssertEqual(viewModel.categorySpending[0].percentage, 100.0)
    }

    func testCategorySpendingMultipleCategories() async throws {
        let (viewModel, mockData) = makeViewModel()
        let cat0 = mockData.categories[0].id
        let cat1 = mockData.categories[1].id
        try await mockData.addTransaction(Transaction(amount: -30.0, categoryId: cat0))
        try await mockData.addTransaction(Transaction(amount: -70.0, categoryId: cat1))
        viewModel.refreshData()

        XCTAssertEqual(viewModel.categorySpending.count, 2)
        // Sorted descending by amount
        XCTAssertEqual(viewModel.categorySpending[0].amount, 70.0)
        XCTAssertEqual(viewModel.categorySpending[1].amount, 30.0)
    }

    // MARK: - hasTransactions

    func testHasTransactionsEmpty() {
        let (viewModel, _) = makeViewModel()
        XCTAssertFalse(viewModel.hasTransactions)
    }

    func testHasTransactionsWithData() async throws {
        let (viewModel, mockData) = makeViewModel()
        let categoryId = mockData.categories[0].id
        try await mockData.addTransaction(Transaction(amount: -5.0, categoryId: categoryId))
        viewModel.refreshData()

        XCTAssertTrue(viewModel.hasTransactions)
    }

    // MARK: - Balance Calculations

    func testTotalBalance() async throws {
        let (viewModel, mockData) = makeViewModel()
        let cat0 = mockData.categories[0].id
        let cat10 = mockData.categories[10].id
        try await mockData.addTransaction(Transaction(amount: -50.0, categoryId: cat0))
        try await mockData.addTransaction(Transaction(amount: 100.0, categoryId: cat10))
        viewModel.refreshData()

        XCTAssertEqual(viewModel.totalBalance, 50.0)
    }

    func testRecentTransactionsLimited() async throws {
        let (viewModel, mockData) = makeViewModel()
        let categoryId = mockData.categories[0].id

        for i in 0..<15 {
            try await mockData.addTransaction(Transaction(amount: Double(-i), categoryId: categoryId))
        }
        viewModel.refreshData()

        XCTAssertLessThanOrEqual(viewModel.recentTransactions.count, Constants.recentTransactionsCount)
    }
}
