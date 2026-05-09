//
//  DataService.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import Combine
import Foundation

// MARK: - Data Service
@MainActor
class DataService: ObservableObject, DataServiceProtocol {
  static let shared = DataService()

  // MARK: - Published Properties
  @Published var categories: [Category] = []
  @Published var transactions: [Transaction] = []
  @Published var userProfile: UserProfile?
  var lastSyncError: AppError?

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

  // MARK: - Transactions
  private func loadTransactions() {
    transactions = []
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
    transactions.groupedByDate()
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

  // MARK: - Profile Update
  func updateUserProfile(_ profile: UserProfile) async throws {
    userProfile = profile
  }

  // MARK: - Cleanup
  func deleteAllTransactions() async throws {
    transactions.removeAll()
  }

  func deleteUserProfile() async throws {
    userProfile = nil
  }
}
