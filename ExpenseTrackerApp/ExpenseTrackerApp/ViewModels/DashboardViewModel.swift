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
    @Published var netWorth: Double = 0
    @Published var totalIncomeThisMonth: Double = 0
    @Published var totalExpensesThisMonth: Double = 0
    @Published var budget: Budget?
    @Published var recentTransactions: [Transaction] = []
    @Published var upcomingBills: [RecurringTransaction] = []
    @Published var categories: [UUID: Category] = [:]
    @Published var accounts: [UUID: Account] = [:]

    // Alias properties for view compatibility
    var transactions: [Transaction] { dataService.transactions }
    var recurringTransactions: [RecurringTransaction] { dataService.recurringTransactions }
    var budgets: [Budget] { dataService.budgets }

    // Additional aliases for view access
    var recurringTransactionList: [RecurringTransaction] { dataService.recurringTransactions }

    // MARK: - Dependencies
    private let dataService = MockDataService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init() {
        setupBindings()
        refreshData()
    }

    // MARK: - Setup
    private func setupBindings() {
        // Listen for transaction changes
        NotificationCenter.default.publisher(for: .transactionAdded)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshData() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .transactionDeleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshData() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .transactionUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshData() }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading
    func refreshData() {
        // Balance & Net Worth
        totalBalance = dataService.totalBalance
        netWorth = dataService.netWorth

        // Monthly stats
        totalIncomeThisMonth = dataService.totalIncomeThisMonth
        totalExpensesThisMonth = dataService.totalExpensesThisMonth

        // Budget
        budget = dataService.budgets.first { $0.isOverallBudget }

        // Recent transactions (today's)
        recentTransactions = dataService.transactions.filter { $0.isToday }.prefix(5).map { $0 }

        // Upcoming bills
        upcomingBills = dataService.recurringTransactions
            .filter { $0.isActive && $0.daysUntilDue <= 7 }
            .prefix(3)
            .map { $0 }

        // Build lookup dictionaries
        categories = Dictionary(uniqueKeysWithValues: dataService.categories.map { ($0.id, $0) })
        accounts = Dictionary(uniqueKeysWithValues: dataService.accounts.map { ($0.id, $0) })
    }

    func refresh() async {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 300_000_000)
        refreshData()
    }

    // MARK: - Helper Methods
    func category(for id: UUID) -> Category? {
        categories[id] ?? dataService.category(for: id)
    }

    func account(for id: UUID) -> Account? {
        accounts[id] ?? dataService.account(for: id)
    }

    func activeRecurringCount() -> Int {
        dataService.recurringTransactions.filter { $0.isActive }.count
    }
}
