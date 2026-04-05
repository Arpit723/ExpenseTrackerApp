//
//  MockDataService.swift
//  ExpenseTrackerAppTests
//
//  Created by Arpit Parekh on 05/04/26.
//

import Foundation
import Combine
@testable import ExpenseTrackerApp

// MARK: - Mock Data Service
@MainActor
class MockDataService: ObservableObject, DataServiceProtocol {
    @Published var transactions: [Transaction] = []
    @Published var categories: [ExpenseTrackerApp.Category] = ExpenseTrackerApp.Category.defaultCategories
    @Published var userProfile: UserProfile?

    // MARK: - Computed Properties
    var totalBalance: Double {
        transactions.reduce(0) { $0 + $1.amount }
    }

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

    // MARK: - Load Data
    func loadData() {
        // No-op for mock. Tests populate data directly.
    }

    // MARK: - Helper Methods
    func category(for id: UUID) -> ExpenseTrackerApp.Category? {
        categories.first { $0.id == id }
    }

    func groupedTransactions() -> [(String, [Transaction])] {
        let sorted = transactions.sorted { $0.date > $1.date }
        let grouped = Dictionary(grouping: sorted) { $0.dateGroupTitle }

        let groupOrder = ["Today", "Yesterday", "This Week", "This Month"]
        return grouped.sorted { pair1, pair2 in
            if let idx1 = groupOrder.firstIndex(of: pair1.key),
               let idx2 = groupOrder.firstIndex(of: pair2.key) {
                return idx1 < idx2
            }
            return pair1.key > pair2.key
        }
    }

    // MARK: - CRUD Operations
    func addTransaction(_ transaction: Transaction) {
        transactions.insert(transaction, at: 0)
    }

    func updateTransaction(_ transaction: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            var updated = transaction
            updated.updatedAt = Date()
            transactions[index] = updated
        }
    }

    func deleteTransaction(_ transaction: Transaction) {
        transactions.removeAll { $0.id == transaction.id }
    }
}
