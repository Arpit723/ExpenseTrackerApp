//
//  TransactionViewModelTests.swift
//  ExpenseTrackerAppTests
//
//  Created by Arpit Parekh on 25/04/26.
//

import XCTest
import Combine
@testable import ExpenseTrackerApp

@MainActor
final class TransactionViewModelTests: XCTestCase {

    private func makeViewModel() -> (TransactionViewModel, MockDataService) {
        let mockData = MockDataService()
        let viewModel = TransactionViewModel(dataService: mockData)
        return (viewModel, mockData)
    }

    // Helper: add transactions then reload
    private func loadData(_ viewModel: TransactionViewModel, _ mockData: MockDataService) {
        viewModel.loadTransactions()
    }

    // MARK: - Initial State

    func testInitialState() {
        let (viewModel, _) = makeViewModel()
        XCTAssertTrue(viewModel.transactions.isEmpty)
        XCTAssertTrue(viewModel.filteredTransactions.isEmpty)
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertEqual(viewModel.selectedFilter, .all)
        XCTAssertEqual(viewModel.selectedSort, .dateDescending)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }

    // MARK: - Categories

    func testCategoriesReturnsDataServiceCategories() {
        let (viewModel, _) = makeViewModel()
        XCTAssertEqual(viewModel.categories.count, Category.defaultCategories.count)
    }

    // MARK: - Load Transactions

    func testLoadTransactions() async throws {
        let (viewModel, mockData) = makeViewModel()
        let categoryId = mockData.categories[0].id
        try await mockData.addTransaction(Transaction(amount: -25.0, categoryId: categoryId))

        viewModel.loadTransactions()

        XCTAssertEqual(viewModel.transactions.count, 1)
        XCTAssertEqual(viewModel.filteredTransactions.count, 1)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Add Transaction

    func testAddTransaction() async throws {
        let (viewModel, mockData) = makeViewModel()
        let categoryId = mockData.categories[0].id
        let transaction = Transaction(amount: -50.0, categoryId: categoryId)

        viewModel.addTransaction(transaction)

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(mockData.transactions.count, 1)
        XCTAssertEqual(viewModel.transactions.count, 1)
        XCTAssertNil(viewModel.error)
    }

    // MARK: - Update Transaction

    func testUpdateTransaction() async throws {
        let (viewModel, mockData) = makeViewModel()
        let categoryId = mockData.categories[0].id
        var transaction = Transaction(amount: -25.0, categoryId: categoryId)
        try await mockData.addTransaction(transaction)

        transaction.amount = -30.0
        viewModel.updateTransaction(transaction)

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(viewModel.transactions.first?.amount, -30.0)
        XCTAssertNil(viewModel.error)
    }

    // MARK: - Delete Transaction

    func testDeleteTransaction() async throws {
        let (viewModel, mockData) = makeViewModel()
        let categoryId = mockData.categories[0].id
        let transaction = Transaction(amount: -10.0, categoryId: categoryId)
        try await mockData.addTransaction(transaction)

        viewModel.deleteTransaction(transaction)

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertTrue(viewModel.transactions.isEmpty)
        XCTAssertNil(viewModel.error)
    }

    // MARK: - Filter: All

    func testFilterAllShowsEverything() async throws {
        let (viewModel, mockData) = makeViewModel()
        let cat0 = mockData.categories[0].id
        let cat10 = mockData.categories[10].id
        try await mockData.addTransaction(Transaction(amount: -50.0, categoryId: cat0))
        try await mockData.addTransaction(Transaction(amount: 100.0, categoryId: cat10))
        loadData(viewModel, mockData)

        viewModel.selectedFilter = .all
        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertEqual(viewModel.filteredTransactions.count, 2)
    }

    // MARK: - Filter: Expenses

    func testFilterExpensesOnly() async throws {
        let (viewModel, mockData) = makeViewModel()
        let cat0 = mockData.categories[0].id
        let cat10 = mockData.categories[10].id
        try await mockData.addTransaction(Transaction(amount: -50.0, categoryId: cat0))
        try await mockData.addTransaction(Transaction(amount: 100.0, categoryId: cat10))
        loadData(viewModel, mockData)

        viewModel.selectedFilter = .expenses
        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertEqual(viewModel.filteredTransactions.count, 1)
        XCTAssertTrue(viewModel.filteredTransactions.first?.isExpense ?? false)
    }

    // MARK: - Filter: Income

    func testFilterIncomeOnly() async throws {
        let (viewModel, mockData) = makeViewModel()
        let cat0 = mockData.categories[0].id
        let cat10 = mockData.categories[10].id
        try await mockData.addTransaction(Transaction(amount: -50.0, categoryId: cat0))
        try await mockData.addTransaction(Transaction(amount: 100.0, categoryId: cat10))
        loadData(viewModel, mockData)

        viewModel.selectedFilter = .income
        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertEqual(viewModel.filteredTransactions.count, 1)
        XCTAssertTrue(viewModel.filteredTransactions.first?.isIncome ?? false)
    }

    // MARK: - Search

    func testSearchByPayee() async throws {
        let (viewModel, mockData) = makeViewModel()
        let categoryId = mockData.categories[0].id
        try await mockData.addTransaction(Transaction(amount: -10.0, categoryId: categoryId, payee: "Starbucks"))
        try await mockData.addTransaction(Transaction(amount: -20.0, categoryId: categoryId, payee: "Walmart"))
        loadData(viewModel, mockData)

        viewModel.searchText = "starbucks"
        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertEqual(viewModel.filteredTransactions.count, 1)
        XCTAssertEqual(viewModel.filteredTransactions.first?.payee, "Starbucks")
    }

    func testSearchByNotes() async throws {
        let (viewModel, mockData) = makeViewModel()
        let categoryId = mockData.categories[0].id
        try await mockData.addTransaction(Transaction(amount: -10.0, categoryId: categoryId, notes: "Monthly subscription"))
        try await mockData.addTransaction(Transaction(amount: -20.0, categoryId: categoryId, notes: "Grocery shopping"))
        loadData(viewModel, mockData)

        viewModel.searchText = "subscription"
        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertEqual(viewModel.filteredTransactions.count, 1)
        XCTAssertEqual(viewModel.filteredTransactions.first?.notes, "Monthly subscription")
    }

    func testSearchCaseInsensitive() async throws {
        let (viewModel, mockData) = makeViewModel()
        let categoryId = mockData.categories[0].id
        try await mockData.addTransaction(Transaction(amount: -10.0, categoryId: categoryId, payee: "Amazon"))
        loadData(viewModel, mockData)

        viewModel.searchText = "AMAZON"
        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertEqual(viewModel.filteredTransactions.count, 1)
    }

    func testSearchNoMatchReturnsEmpty() async throws {
        let (viewModel, mockData) = makeViewModel()
        let categoryId = mockData.categories[0].id
        try await mockData.addTransaction(Transaction(amount: -10.0, categoryId: categoryId, payee: "Starbucks"))
        loadData(viewModel, mockData)

        viewModel.searchText = "netflix"
        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertTrue(viewModel.filteredTransactions.isEmpty)
    }

    // MARK: - Sort

    func testSortByDateDescending() async throws {
        let (viewModel, mockData) = makeViewModel()
        let categoryId = mockData.categories[0].id
        let older = Transaction(amount: -10.0, categoryId: categoryId, date: Date().addingTimeInterval(-86400))
        let newer = Transaction(amount: -20.0, categoryId: categoryId, date: Date())
        try await mockData.addTransaction(older)
        try await mockData.addTransaction(newer)
        loadData(viewModel, mockData)

        viewModel.selectedSort = .dateDescending
        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertEqual(viewModel.filteredTransactions.first?.id, newer.id)
    }

    func testSortByDateAscending() async throws {
        let (viewModel, mockData) = makeViewModel()
        let categoryId = mockData.categories[0].id
        let older = Transaction(amount: -10.0, categoryId: categoryId, date: Date().addingTimeInterval(-86400))
        let newer = Transaction(amount: -20.0, categoryId: categoryId, date: Date())
        try await mockData.addTransaction(older)
        try await mockData.addTransaction(newer)
        loadData(viewModel, mockData)

        viewModel.selectedSort = .dateAscending
        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertEqual(viewModel.filteredTransactions.first?.id, older.id)
    }

    func testSortByAmountDescending() async throws {
        let (viewModel, mockData) = makeViewModel()
        let categoryId = mockData.categories[0].id
        try await mockData.addTransaction(Transaction(amount: -10.0, categoryId: categoryId))
        try await mockData.addTransaction(Transaction(amount: -50.0, categoryId: categoryId))
        loadData(viewModel, mockData)

        viewModel.selectedSort = .amountDescending
        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertEqual(abs(viewModel.filteredTransactions.first?.amount ?? 0), 50.0)
    }

    func testSortByAmountAscending() async throws {
        let (viewModel, mockData) = makeViewModel()
        let categoryId = mockData.categories[0].id
        try await mockData.addTransaction(Transaction(amount: -50.0, categoryId: categoryId))
        try await mockData.addTransaction(Transaction(amount: -10.0, categoryId: categoryId))
        loadData(viewModel, mockData)

        viewModel.selectedSort = .amountAscending
        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertEqual(abs(viewModel.filteredTransactions.first?.amount ?? 0), 10.0)
    }

    // MARK: - Computed Properties

    func testTotalExpensesThisMonth() async throws {
        let (viewModel, mockData) = makeViewModel()
        let cat0 = mockData.categories[0].id
        let cat10 = mockData.categories[10].id
        try await mockData.addTransaction(Transaction(amount: -50.0, categoryId: cat0))
        try await mockData.addTransaction(Transaction(amount: 100.0, categoryId: cat10))
        viewModel.loadTransactions()

        XCTAssertEqual(viewModel.totalExpensesThisMonth, -50.0)
    }

    func testTotalIncomeThisMonth() async throws {
        let (viewModel, mockData) = makeViewModel()
        let cat0 = mockData.categories[0].id
        let cat10 = mockData.categories[10].id
        try await mockData.addTransaction(Transaction(amount: -50.0, categoryId: cat0))
        try await mockData.addTransaction(Transaction(amount: 100.0, categoryId: cat10))
        viewModel.loadTransactions()

        XCTAssertEqual(viewModel.totalIncomeThisMonth, 100.0)
    }

    func testNetThisMonth() async throws {
        let (viewModel, mockData) = makeViewModel()
        let cat0 = mockData.categories[0].id
        let cat10 = mockData.categories[10].id
        try await mockData.addTransaction(Transaction(amount: -30.0, categoryId: cat0))
        try await mockData.addTransaction(Transaction(amount: 100.0, categoryId: cat10))
        viewModel.loadTransactions()

        XCTAssertEqual(viewModel.netThisMonth, 70.0)
    }

    // MARK: - Grouped Transactions

    func testGroupedTransactionsNotEmpty() async throws {
        let (viewModel, mockData) = makeViewModel()
        let categoryId = mockData.categories[0].id
        try await mockData.addTransaction(Transaction(amount: -10.0, categoryId: categoryId))
        viewModel.loadTransactions()

        XCTAssertFalse(viewModel.groupedTransactions.isEmpty)
    }

    func testGroupedTransactionsEmptyWhenNoData() {
        let (viewModel, _) = makeViewModel()
        XCTAssertTrue(viewModel.groupedTransactions.isEmpty)
    }

    // MARK: - Category Lookup

    func testCategoryForTransaction() async throws {
        let (viewModel, mockData) = makeViewModel()
        let category = mockData.categories[0]
        let transaction = Transaction(amount: -10.0, categoryId: category.id)
        try await mockData.addTransaction(transaction)
        viewModel.loadTransactions()

        let found = viewModel.category(for: transaction)
        XCTAssertEqual(found?.name, category.name)
    }

    func testCategoryForTransactionReturnsNilForUnknown() async throws {
        let (viewModel, _) = makeViewModel()
        let transaction = Transaction(amount: -10.0, categoryId: UUID())

        let found = viewModel.category(for: transaction)
        XCTAssertNil(found)
    }

    // MARK: - Delete at IndexSet

    func testDeleteTransactionsAtOffsets() async throws {
        let (viewModel, mockData) = makeViewModel()
        let categoryId = mockData.categories[0].id
        let tx1 = Transaction(amount: -10.0, categoryId: categoryId)
        let tx2 = Transaction(amount: -20.0, categoryId: categoryId)
        try await mockData.addTransaction(tx1)
        try await mockData.addTransaction(tx2)
        viewModel.loadTransactions()

        let groupIndex = 0
        viewModel.deleteTransactions(at: IndexSet(integer: 0), in: groupIndex)

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(viewModel.transactions.count, 1)
    }

    // MARK: - TransactionFilter

    func testTransactionFilterTitles() {
        XCTAssertEqual(TransactionFilter.all.title, "All")
        XCTAssertEqual(TransactionFilter.income.title, "Income")
        XCTAssertEqual(TransactionFilter.expenses.title, "Expenses")
    }

    func testTransactionFilterAllCases() {
        XCTAssertEqual(TransactionFilter.allCases.count, 3)
    }

    // MARK: - TransactionSort

    func testTransactionSortTitles() {
        XCTAssertEqual(TransactionSort.dateDescending.title, "Newest First")
        XCTAssertEqual(TransactionSort.dateAscending.title, "Oldest First")
        XCTAssertEqual(TransactionSort.amountDescending.title, "Highest Amount")
        XCTAssertEqual(TransactionSort.amountAscending.title, "Lowest Amount")
    }

    func testTransactionSortAllCases() {
        XCTAssertEqual(TransactionSort.allCases.count, 4)
    }
}
