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

    // MARK: - Dependencies
    private let dataService: DataService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(dataService: DataService = .shared) {
        self.dataService = dataService
        setupBindings()
        refreshData()
    }

    // MARK: - Setup
    private func setupBindings() {
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
        totalBalance = dataService.totalBalance
        totalIncomeThisMonth = dataService.totalIncomeThisMonth
        totalExpensesThisMonth = dataService.totalExpensesThisMonth

        // Recent transactions (last 10)
        recentTransactions = dataService.transactions
            .sorted { $0.date > $1.date }
            .prefix(Constants.recentTransactionsCount)
            .map { $0 }

        // Build lookup dictionary
        categories = Dictionary(uniqueKeysWithValues: dataService.categories.map { ($0.id, $0) })
    }

    func refresh() async {
        try? await Task.sleep(nanoseconds: 300_000_000)
        refreshData()
    }

    // MARK: - Helper Methods
    func category(for id: UUID) -> Category? {
        categories[id] ?? dataService.category(for: id)
    }
}
