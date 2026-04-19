//
//  DataServiceProtocol.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 05/04/26.
//

import Foundation
import Combine

// MARK: - Data Service Protocol
@MainActor
protocol DataServiceProtocol: ObservableObject {
    var transactions: [Transaction] { get }
    var categories: [Category] { get }
    var userProfile: UserProfile? { get }
    var totalBalance: Double { get }
    var totalExpensesThisMonth: Double { get }
    var totalIncomeThisMonth: Double { get }

    func loadData() async throws
    func category(for id: UUID) -> Category?
    func groupedTransactions() -> [(String, [Transaction])]
    func addTransaction(_ transaction: Transaction) async throws
    func updateTransaction(_ transaction: Transaction) async throws
    func deleteTransaction(_ transaction: Transaction) async throws
}
