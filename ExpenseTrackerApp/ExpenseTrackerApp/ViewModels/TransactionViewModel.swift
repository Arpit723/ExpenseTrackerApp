//
//  TransactionViewModel.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Transaction Filter
enum TransactionFilter: CaseIterable {
    case all, income, expenses

    var title: String {
        switch self {
        case .all: return "All"
        case .income: return "Income"
        case .expenses: return "Expenses"
        }
    }
}

// MARK: - Transaction Sort
enum TransactionSort: CaseIterable {
    case dateDescending, dateAscending, amountDescending, amountAscending

    var title: String {
        switch self {
        case .dateDescending: return "Newest First"
        case .dateAscending: return "Oldest First"
        case .amountDescending: return "Highest Amount"
        case .amountAscending: return "Lowest Amount"
        }
    }
}

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
    @Published var error: AppError?

    // MARK: - Dependencies
    private let dataService: any DataServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    var categories: [Category] { dataService.categories }

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
    init(dataService: any DataServiceProtocol = DataService.shared) {
        self.dataService = dataService
        setupBindings()
        loadTransactions()
    }

    // MARK: - Setup
    private func setupBindings() {
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
        try? await Task.sleep(nanoseconds: 500_000_000)
        loadTransactions()
    }

    // MARK: - CRUD Operations
    func addTransaction(_ transaction: Transaction) {
        Task {
            do {
                try await dataService.addTransaction(transaction)
                loadTransactions()
            } catch {
                self.error = AppError.from(firebaseError: error)
            }
        }
    }

    func updateTransaction(_ transaction: Transaction) {
        Task {
            do {
                try await dataService.updateTransaction(transaction)
                loadTransactions()
            } catch {
                self.error = AppError.from(firebaseError: error)
            }
        }
    }

    func deleteTransaction(_ transaction: Transaction) {
        Task {
            do {
                try await dataService.deleteTransaction(transaction)
                loadTransactions()
            } catch {
                self.error = AppError.from(firebaseError: error)
            }
        }
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

        // Search across payee and notes (FR-2.5)
        if !searchText.isEmpty {
            result = result.filter { transaction in
                let payeeMatch = transaction.payee?.localizedCaseInsensitiveContains(searchText) ?? false
                let notesMatch = transaction.notes?.localizedCaseInsensitiveContains(searchText) ?? false
                return payeeMatch || notesMatch
            }
        }

        // Filter by type (FR-2.6)
        switch selectedFilter {
        case .all:
            break
        case .expenses:
            result = result.filter { $0.isExpense }
        case .income:
            result = result.filter { $0.isIncome }
        }

        // Sort
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
}
