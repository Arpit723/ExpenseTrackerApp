//
//  DashboardViewModel.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var totalBalance: Double = 0
    @Published var totalIncomeThisMonth: Double = 0
    @Published var totalExpensesThisMonth: Double = 0
    @Published var recentTransactions: [Transaction] = []
    @Published var categories: [UUID: Category] = [:]
    @Published var error: AppError?

    // MARK: - Dependencies
    private let dataService: any DataServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(dataService: any DataServiceProtocol = DataService.shared) {
        self.dataService = dataService
        setupBindings()
        refreshData()
    }

    // MARK: - Setup
    private func setupBindings() {
        // Listen to all transaction change notifications with a single merged pipeline
        // to avoid double-refreshing (the view also has .onReceive — those are now removed)
        Publishers.Merge3(
            NotificationCenter.default.publisher(for: .transactionAdded),
            NotificationCenter.default.publisher(for: .transactionDeleted),
            NotificationCenter.default.publisher(for: .transactionUpdated)
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in self?.refreshData() }
        .store(in: &cancellables)
    }

    // MARK: - Data Loading
    func refreshData() {
        totalBalance = dataService.totalBalance
        totalIncomeThisMonth = dataService.totalIncomeThisMonth
        totalExpensesThisMonth = dataService.totalExpensesThisMonth

        // Recent transactions (last 10)
        recentTransactions = Array(dataService.transactions
            .sorted { $0.date > $1.date }
            .prefix(Constants.recentTransactionsCount)
        )

        // Build lookup dictionary
        categories = Dictionary(uniqueKeysWithValues: dataService.categories.map { ($0.id, $0) })
    }

    func refresh() async {
        try? await Task.sleep(nanoseconds: 300_000_000)
        refreshData()
    }

    func loadData() async {
        do {
            try await dataService.loadData()
            refreshData()
        } catch {
            self.error = AppError.from(firebaseError: error)
        }
    }

    // MARK: - Helper Methods
    func category(for id: UUID) -> Category? {
        categories[id] ?? dataService.category(for: id)
    }

    // MARK: - Dashboard Features (Phase 4)

    var todaySpending: Double {
        dataService.transactions
            .filter { Calendar.current.isDateInToday($0.date) && $0.isExpense }
            .reduce(0) { $0 + abs($1.amount) }
    }

    var hasTransactions: Bool {
        !dataService.transactions.isEmpty
    }

    var categorySpending: [(category: Category, amount: Double, percentage: Double)] {
        let thisMonthExpenses = dataService.transactions.filter { $0.date.isThisMonth && $0.isExpense }
        let total = thisMonthExpenses.reduce(0.0) { $0 + abs($1.amount) }
        guard total > 0 else { return [] }

        let grouped = Dictionary(grouping: thisMonthExpenses) { $0.categoryId }
        return grouped.map { categoryId, txns in
            let amount = txns.reduce(0.0) { $0 + abs($1.amount) }
            let cat = dataService.category(for: categoryId)
            return (category: cat ?? Category.defaultCategories[0], amount: amount, percentage: (amount / total) * 100)
        }
        .sorted { $0.amount > $1.amount }
    }
}
