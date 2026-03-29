//
//  TransactionViewModel.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Transaction ViewModel
@MainActor
class TransactionViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var transactions: [Transaction] = []
    @Published var filteredTransactions: [Transaction] = []
    @Published var searchText: String = ""
    @Published var selectedFilter: TransactionFilter = .all
    @Published var selectedSort: TransactionSort = .dateDescending
    @Published var isLoading: Bool = false
    @Published var error: Error?

    // MARK: - Dependencies
    private let dataService: MockDataService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    var categories: [Category] { dataService.categories }
    var accounts: [Account] { dataService.accounts }

    var totalExpensesThisMonth: Double {
        transactions
            .filter { $0.date.isThisMonth && $0.isExpense }
            .reduce(0) { $0 + $1.amount }
    }

    var totalIncomeThisMonth: Double {
        transactions
            .filter { $0.date.isThisMonth && $0.isIncome }
            .reduce(0) { $0 + $1.amount }
    }

    var netThisMonth: Double {
        totalIncomeThisMonth + totalExpensesThisMonth
    }

    var todaySpending: Double {
        transactions
            .filter { $0.isToday && $0.isExpense }
            .reduce(0) { $0 + $1.amount }
    }

    var groupedTransactions: [(String, [Transaction])] {
        let grouped = Dictionary(grouping: filteredTransactions) { $0.dateGroupTitle }
        let groupOrder = ["Today", "Yesterday", "This Week", "This Month"]

        return grouped.sorted { pair1, pair2 in
            if let idx1 = groupOrder.firstIndex(of: pair1.key),
               let idx2 = groupOrder.firstIndex(of: pair2.key) {
                return idx1 < idx2
            }
            return pair1.key > pair2.key
        }
    }

    // MARK: - Initialization
    init(dataService: MockDataService = .shared) {
        self.dataService = dataService
        setupBindings()
        loadTransactions()
    }

    // MARK: - Setup
    private func setupBindings() {
        // Combine search, filter, and sort into a single pipeline
        Publishers.CombineLatest3($searchText, $selectedFilter, $selectedSort)
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _, _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading
    func loadTransactions() {
        isLoading = true
        transactions = dataService.transactions
        applyFilters()
        isLoading = false
    }

    func refreshTransactions() async {
        isLoading = true
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        loadTransactions()
    }

    // MARK: - CRUD Operations
    func addTransaction(_ transaction: Transaction) {
        dataService.addTransaction(transaction)
        loadTransactions()
        // Post notification for other views to update
        NotificationCenter.default.post(name: .transactionAdded, object: transaction)
    }

    func updateTransaction(_ transaction: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            // First, revert the old transaction's effect on account balance
            if let oldTransaction = transactions.first(where: { $0.id == transaction.id }),
               let accountIndex = dataService.accounts.firstIndex(where: { $0.id == oldTransaction.accountId }) {
                dataService.accounts[accountIndex].balance -= oldTransaction.amount
            }

            // Update the transaction in data service
            var updatedTransaction = transaction
            updatedTransaction.updatedAt = Date()

            // Apply new transaction's effect on account balance
            if let accountIndex = dataService.accounts.firstIndex(where: { $0.id == transaction.accountId }) {
                dataService.accounts[accountIndex].balance += transaction.amount
            }

            // Update in data service
            dataService.transactions.removeAll { $0.id == transaction.id }
            dataService.transactions.insert(updatedTransaction, at: 0)
        }
        loadTransactions()
        NotificationCenter.default.post(name: .transactionUpdated, object: transaction)
    }

    func deleteTransaction(_ transaction: Transaction) {
        dataService.deleteTransaction(transaction)
        loadTransactions()
        NotificationCenter.default.post(name: .transactionDeleted, object: transaction)
    }

    func deleteTransactions(at offsets: IndexSet, in groupIndex: Int) {
        let group = groupedTransactions[groupIndex]
        for index in offsets {
            let transaction = group.1[index]
            deleteTransaction(transaction)
        }
    }

    // MARK: - Filtering & Sorting
    private func applyFilters() {
        var result = transactions

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { transaction in
                let payeeMatch = transaction.payee?.localizedCaseInsensitiveContains(searchText) ?? false
                let notesMatch = transaction.notes?.localizedCaseInsensitiveContains(searchText) ?? false
                let categoryMatch = dataService.category(for: transaction.categoryId)?.name.localizedCaseInsensitiveContains(searchText) ?? false
                return payeeMatch || notesMatch || categoryMatch
            }
        }

        // Apply type filter
        switch selectedFilter {
        case .all:
            break
        case .expenses:
            result = result.filter { $0.isExpense }
        case .income:
            result = result.filter { $0.isIncome }
        case .transfers:
            result = result.filter { dataService.category(for: $0.categoryId)?.name == "Transfer" }
        }

        // Apply sort
        switch selectedSort {
        case .dateDescending:
            result.sort { $0.date > $1.date }
        case .dateAscending:
            result.sort { $0.date < $1.date }
        case .amountDescending:
            result.sort { abs($0.amount) > abs($1.amount) }
        case .amountAscending:
            result.sort { abs($0.amount) < abs($1.amount) }
        }

        filteredTransactions = result
    }

    // MARK: - Helper Methods
    func category(for transaction: Transaction) -> Category? {
        dataService.category(for: transaction.categoryId)
    }

    func account(for transaction: Transaction) -> Account? {
        dataService.account(for: transaction.accountId)
    }

    func transactionsForAccount(_ accountId: UUID) -> [Transaction] {
        transactions.filter { $0.accountId == accountId }
    }

    func transactionsForCategory(_ categoryId: UUID) -> [Transaction] {
        transactions.filter { $0.categoryId == categoryId }
    }

    // MARK: - Statistics
    func spendingByCategory() -> [(Category, Double)] {
        var spending: [UUID: Double] = [:]

        for transaction in transactions where transaction.isExpense && transaction.date.isThisMonth {
            spending[transaction.categoryId, default: 0] += abs(transaction.amount)
        }

        return spending.compactMap { (categoryId, amount) -> (Category, Double)? in
            guard let category = dataService.category(for: categoryId) else { return nil }
            return (category, amount)
        }.sorted { $0.1 > $1.1 }
    }

    func averageDailySpending() -> Double {
        let calendar = Calendar.current
        let daysInMonth = calendar.dateComponents([.day], from: Date().startOfMonth, to: Date()).day ?? 1
        return abs(totalExpensesThisMonth) / Double(max(daysInMonth, 1))
    }
}
