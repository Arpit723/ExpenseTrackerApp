//
//  DataService.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import Foundation
import Combine

// MARK: - Data Service
class DataService: ObservableObject, DataServiceProtocol {
    static let shared = DataService()

    // MARK: - Published Properties
    @Published var categories: [Category] = []
    @Published var transactions: [Transaction] = []
    @Published var userProfile: UserProfile?

    private init() {
        loadFromMemory()
    }

    // MARK: - Load Data
    private func loadFromMemory() {
        loadCategories()
        loadTransactions()
        loadUserProfile()
    }

    func loadData() async throws {
        loadFromMemory()
    }

    // MARK: - Categories
    private func loadCategories() {
        categories = Category.defaultCategories
    }

    // MARK: - Transactions (Sample Data)
    private func loadTransactions() {
        let calendar = Calendar.current
        let now = Date()

        transactions = [
            Transaction(
                amount: -5.50,
                categoryId: categories[0].id,
                date: now,
                payee: "Starbucks",
                notes: "Morning coffee"
            ),
            Transaction(
                amount: -35.00,
                categoryId: categories[1].id,
                date: now,
                payee: "Shell Gas Station",
                notes: "Fill up tank"
            ),
            Transaction(
                amount: -4.50,
                categoryId: categories[3].id,
                date: now,
                payee: "App Store",
                notes: "App purchase"
            ),
            Transaction(
                amount: -127.50,
                categoryId: categories[8].id,
                date: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                payee: "Whole Foods",
                notes: "Weekly groceries"
            ),
            Transaction(
                amount: -45.00,
                categoryId: categories[5].id,
                date: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                payee: "CVS Pharmacy",
                notes: "Prescription"
            ),
            Transaction(
                amount: 5200.00,
                categoryId: categories[10].id,
                date: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                payee: "Employer Inc.",
                notes: "Monthly salary"
            ),
            Transaction(
                amount: -89.00,
                categoryId: categories[4].id,
                date: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                payee: "Electric Company",
                notes: "Electric bill"
            ),
            Transaction(
                amount: -250.00,
                categoryId: categories[2].id,
                date: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
                payee: "Apple Store",
                notes: "New AirPods case"
            ),
            Transaction(
                amount: -65.00,
                categoryId: categories[3].id,
                date: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
                payee: "AMC Theater",
                notes: "Movie tickets"
            ),
            Transaction(
                amount: -180.00,
                categoryId: categories[1].id,
                date: calendar.date(byAdding: .day, value: -5, to: now) ?? now,
                payee: "Uber",
                notes: "Airport ride"
            ),
            Transaction(
                amount: -420.00,
                categoryId: categories[0].id,
                date: calendar.date(byAdding: .day, value: -5, to: now) ?? now,
                payee: "Restaurant",
                notes: "Dinner with friends"
            ),
            Transaction(
                amount: -15.99,
                categoryId: categories[3].id,
                date: calendar.date(byAdding: .day, value: -7, to: now) ?? now,
                payee: "Netflix",
                notes: "Monthly subscription"
            ),
            Transaction(
                amount: -10.99,
                categoryId: categories[3].id,
                date: calendar.date(byAdding: .day, value: -7, to: now) ?? now,
                payee: "Spotify",
                notes: "Monthly subscription"
            ),
            Transaction(
                amount: -340.00,
                categoryId: categories[8].id,
                date: calendar.date(byAdding: .day, value: -10, to: now) ?? now,
                payee: "Trader Joe's",
                notes: "Weekly groceries"
            ),
            Transaction(
                amount: -89.00,
                categoryId: categories[4].id,
                date: calendar.date(byAdding: .day, value: -10, to: now) ?? now,
                payee: "Internet Provider",
                notes: "Monthly internet"
            ),
            Transaction(
                amount: -200.00,
                categoryId: categories[7].id,
                date: calendar.date(byAdding: .day, value: -14, to: now) ?? now,
                payee: "Southwest Airlines",
                notes: "Flight booking"
            )
        ]
    }

    // MARK: - User Profile
    private func loadUserProfile() {
        userProfile = UserProfile(
            preferences: UserPreferences(
                currency: "USD",
                currencySymbol: "$",
                theme: .system
            )
        )
    }

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

    // MARK: - Helper Methods
    func category(for id: UUID) -> Category? {
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
    func addTransaction(_ transaction: Transaction) async throws {
        transactions.insert(transaction, at: 0)
        NotificationCenter.default.post(name: .transactionAdded, object: transaction)
    }

    func updateTransaction(_ transaction: Transaction) async throws {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            var updated = transaction
            updated.updatedAt = Date()
            transactions[index] = updated
        }
        NotificationCenter.default.post(name: .transactionUpdated, object: transaction)
    }

    func deleteTransaction(_ transaction: Transaction) async throws {
        transactions.removeAll { $0.id == transaction.id }
        NotificationCenter.default.post(name: .transactionDeleted, object: transaction)
    }
}
