//
//  MockDataService.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import Foundation
import Combine

// MARK: - Mock Data Service
class MockDataService: ObservableObject {
    static let shared = MockDataService()

    // MARK: - Published Properties
    @Published var accounts: [Account] = []
    @Published var categories: [Category] = []
    @Published var transactions: [Transaction] = []
    @Published var budgets: [Budget] = []
    @Published var goals: [Goal] = []
    @Published var recurringTransactions: [RecurringTransaction] = []
    @Published var userProfile: UserProfile?

    private init() {
        loadMockData()
    }

    // MARK: - Load Mock Data
    func loadMockData() {
        loadCategories()
        loadAccounts()
        loadTransactions()
        loadBudgets()
        loadGoals()
        loadRecurringTransactions()
        loadUserProfile()
    }

    // MARK: - Categories
    private func loadCategories() {
        categories = Category.defaultCategories
    }

    // MARK: - Accounts
    private func loadAccounts() {
        accounts = [
            Account(name: "Main Checking", type: .checking, balance: 3306.78, institution: "Chase Bank"),
            Account(name: "Emergency Fund", type: .savings, balance: 15000.00, institution: "Ally Bank"),
            Account(name: "Vacation Savings", type: .savings, balance: 2400.00, institution: "Ally Bank"),
            Account(name: "Chase Sapphire", type: .creditCard, balance: -1200.00, institution: "Chase"),
            Account(name: "Amex Gold", type: .creditCard, balance: -1145.00, institution: "American Express"),
            Account(name: "Cash Wallet", type: .cash, balance: 150.00),
            Account(name: "401(k)", type: .investment, balance: 30000.00, institution: "Fidelity"),
            Account(name: "Robinhood", type: .investment, balance: 15678.00, institution: "Robinhood")
        ]
    }

    // MARK: - Transactions
    private func loadTransactions() {
        let calendar = Calendar.current
        let now = Date()

        transactions = [
            // Today
            Transaction(
                amount: -5.50,
                categoryId: categories[0].id, // Food & Drinks
                accountId: accounts[3].id, // Chase Sapphire
                date: now,
                payee: "Starbucks",
                notes: "Morning coffee"
            ),
            Transaction(
                amount: -35.00,
                categoryId: categories[1].id, // Transportation
                accountId: accounts[3].id,
                date: now,
                payee: "Shell Gas Station",
                notes: "Fill up tank"
            ),
            Transaction(
                amount: -4.50,
                categoryId: categories[3].id, // Entertainment
                accountId: accounts[3].id,
                date: now,
                payee: "App Store",
                notes: "App purchase"
            ),

            // Yesterday
            Transaction(
                amount: -127.50,
                categoryId: categories[9].id, // Groceries
                accountId: accounts[0].id, // Main Checking
                date: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                payee: "Whole Foods",
                notes: "Weekly groceries"
            ),
            Transaction(
                amount: -45.00,
                categoryId: categories[5].id, // Healthcare
                accountId: accounts[0].id,
                date: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                payee: "CVS Pharmacy",
                notes: "Prescription"
            ),

            // 2 days ago
            Transaction(
                amount: 5200.00,
                categoryId: categories[11].id, // Income
                accountId: accounts[0].id,
                date: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                payee: "Employer Inc.",
                notes: "Monthly salary"
            ),
            Transaction(
                amount: -89.00,
                categoryId: categories[4].id, // Bills
                accountId: accounts[0].id,
                date: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                payee: "Electric Company",
                notes: "Electric bill"
            ),

            // 3 days ago
            Transaction(
                amount: -250.00,
                categoryId: categories[2].id, // Shopping
                accountId: accounts[4].id, // Amex Gold
                date: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
                payee: "Apple Store",
                notes: "New AirPods case"
            ),
            Transaction(
                amount: -65.00,
                categoryId: categories[3].id, // Entertainment
                accountId: accounts[4].id,
                date: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
                payee: "AMC Theater",
                notes: "Movie tickets"
            ),

            // 5 days ago
            Transaction(
                amount: -180.00,
                categoryId: categories[1].id, // Transportation
                accountId: accounts[3].id,
                date: calendar.date(byAdding: .day, value: -5, to: now) ?? now,
                payee: "Uber",
                notes: "Airport ride"
            ),
            Transaction(
                amount: -420.00,
                categoryId: categories[0].id, // Food
                accountId: accounts[3].id,
                date: calendar.date(byAdding: .day, value: -5, to: now) ?? now,
                payee: "Restaurant",
                notes: "Dinner with friends"
            ),

            // 7 days ago
            Transaction(
                amount: -15.99,
                categoryId: categories[3].id, // Entertainment
                accountId: accounts[0].id,
                date: calendar.date(byAdding: .day, value: -7, to: now) ?? now,
                payee: "Netflix",
                notes: "Monthly subscription",
                isRecurring: true
            ),
            Transaction(
                amount: -10.99,
                categoryId: categories[3].id, // Entertainment
                accountId: accounts[0].id,
                date: calendar.date(byAdding: .day, value: -7, to: now) ?? now,
                payee: "Spotify",
                notes: "Monthly subscription",
                isRecurring: true
            ),

            // 10 days ago
            Transaction(
                amount: -340.00,
                categoryId: categories[9].id, // Groceries
                accountId: accounts[0].id,
                date: calendar.date(byAdding: .day, value: -10, to: now) ?? now,
                payee: "Trader Joe's",
                notes: "Weekly groceries"
            ),
            Transaction(
                amount: -89.00,
                categoryId: categories[4].id, // Bills
                accountId: accounts[0].id,
                date: calendar.date(byAdding: .day, value: -10, to: now) ?? now,
                payee: "Internet Provider",
                notes: "Monthly internet"
            ),

            // 14 days ago
            Transaction(
                amount: -500.00,
                categoryId: categories[12].id, // Transfer
                accountId: accounts[6].id, // Transfer to 401k
                date: calendar.date(byAdding: .day, value: -14, to: now) ?? now,
                payee: "401k Contribution",
                notes: "Monthly contribution"
            ),
            Transaction(
                amount: -200.00,
                categoryId: categories[10].id, // Travel
                accountId: accounts[4].id,
                date: calendar.date(byAdding: .day, value: -14, to: now) ?? now,
                payee: "Southwest Airlines",
                notes: "Flight booking"
            )
        ]
    }

    // MARK: - Budgets
    private func loadBudgets() {
        let now = Date()

        budgets = [
            // Overall budget
            Budget(
                amount: 5000.00,
                period: .monthly,
                startDate: now.startOfMonth,
                actualSpent: 3847.00
            ),
            // Category budgets
            Budget(
                categoryId: categories[0].id, // Food & Drinks
                amount: 500.00,
                period: .monthly,
                startDate: now.startOfMonth,
                actualSpent: 420.00
            ),
            Budget(
                categoryId: categories[1].id, // Transportation
                amount: 300.00,
                period: .monthly,
                startDate: now.startOfMonth,
                actualSpent: 180.00
            ),
            Budget(
                categoryId: categories[9].id, // Groceries
                amount: 400.00,
                period: .monthly,
                startDate: now.startOfMonth,
                actualSpent: 340.00
            ),
            Budget(
                categoryId: categories[3].id, // Entertainment
                amount: 150.00,
                period: .monthly,
                startDate: now.startOfMonth,
                actualSpent: 89.00
            ),
            Budget(
                categoryId: categories[2].id, // Shopping
                amount: 500.00,
                period: .monthly,
                startDate: now.startOfMonth,
                actualSpent: 650.00 // Over budget!
            ),
            Budget(
                categoryId: categories[4].id, // Bills
                amount: 200.00,
                period: .monthly,
                startDate: now.startOfMonth,
                actualSpent: 0.00
            )
        ]
    }

    // MARK: - Goals
    private func loadGoals() {
        let calendar = Calendar.current
        let now = Date()

        goals = [
            Goal(
                name: "Vacation Fund",
                targetAmount: 3000.00,
                currentAmount: 2400.00,
                targetDate: calendar.date(byAdding: .month, value: 3, to: now) ?? now,
                priority: .medium,
                icon: "airplane"
            ),
            Goal(
                name: "New Car Down Payment",
                targetAmount: 15000.00,
                currentAmount: 8500.00,
                targetDate: calendar.date(byAdding: .month, value: 9, to: now) ?? now,
                priority: .high,
                icon: "car.fill"
            ),
            Goal(
                name: "Emergency Fund",
                targetAmount: 10000.00,
                currentAmount: 4200.00,
                targetDate: calendar.date(byAdding: .year, value: 1, to: now) ?? now,
                priority: .high,
                icon: "shield.fill"
            ),
            Goal(
                name: "New Laptop",
                targetAmount: 2000.00,
                currentAmount: 1500.00,
                targetDate: calendar.date(byAdding: .month, value: 2, to: now) ?? now,
                priority: .low,
                icon: "laptopcomputer"
            )
        ]
    }

    // MARK: - Recurring Transactions
    private func loadRecurringTransactions() {
        let calendar = Calendar.current
        let now = Date()

        recurringTransactions = [
            // Streaming
            RecurringTransaction(
                name: "Netflix",
                amount: -15.99,
                categoryId: categories[3].id,
                accountId: accounts[0].id,
                frequency: .monthly,
                nextDueDate: calendar.date(byAdding: .day, value: 5, to: now) ?? now
            ),
            RecurringTransaction(
                name: "Spotify",
                amount: -10.99,
                categoryId: categories[3].id,
                accountId: accounts[0].id,
                frequency: .monthly,
                nextDueDate: calendar.date(byAdding: .day, value: 8, to: now) ?? now
            ),
            RecurringTransaction(
                name: "Disney+",
                amount: -13.99,
                categoryId: categories[3].id,
                accountId: accounts[0].id,
                frequency: .monthly,
                nextDueDate: calendar.date(byAdding: .day, value: 12, to: now) ?? now
            ),
            RecurringTransaction(
                name: "YouTube Premium",
                amount: -11.99,
                categoryId: categories[3].id,
                accountId: accounts[0].id,
                frequency: .monthly,
                nextDueDate: calendar.date(byAdding: .day, value: 18, to: now) ?? now
            ),
            // Software
            RecurringTransaction(
                name: "iCloud+",
                amount: -2.99,
                categoryId: categories[2].id,
                accountId: accounts[0].id,
                frequency: .monthly,
                nextDueDate: calendar.date(byAdding: .day, value: 2, to: now) ?? now
            ),
            RecurringTransaction(
                name: "Notion",
                amount: -10.00,
                categoryId: categories[2].id,
                accountId: accounts[0].id,
                frequency: .monthly,
                nextDueDate: calendar.date(byAdding: .day, value: 7, to: now) ?? now
            ),
            RecurringTransaction(
                name: "Adobe Creative Cloud",
                amount: -54.99,
                categoryId: categories[2].id,
                accountId: accounts[0].id,
                frequency: .monthly,
                nextDueDate: calendar.date(byAdding: .day, value: 22, to: now) ?? now
            ),
            // Health & Fitness
            RecurringTransaction(
                name: "Gym Membership",
                amount: -45.00,
                categoryId: categories[5].id,
                accountId: accounts[0].id,
                frequency: .monthly,
                nextDueDate: calendar.date(byAdding: .day, value: 1, to: now) ?? now
            ),
            // Bills
            RecurringTransaction(
                name: "Rent",
                amount: -1500.00,
                categoryId: categories[4].id,
                accountId: accounts[0].id,
                frequency: .monthly,
                nextDueDate: calendar.date(byAdding: .day, value: 1, to: now) ?? now
            ),
            RecurringTransaction(
                name: "Car Insurance",
                amount: -125.00,
                categoryId: categories[1].id,
                accountId: accounts[0].id,
                frequency: .monthly,
                nextDueDate: calendar.date(byAdding: .day, value: 15, to: now) ?? now
            )
        ]
    }

    // MARK: - User Profile
    private func loadUserProfile() {
        userProfile = UserProfile(
            displayName: "John Doe",
            email: "john.doe@example.com",
            preferences: UserPreferences(
                currency: "USD",
                currencySymbol: "$",
                firstDayOfWeek: 2,
                theme: .system,
                language: "en"
            )
        )
    }

    // MARK: - Computed Properties
    var totalBalance: Double {
        accounts.reduce(0) { $0 + $1.balance }
    }

    var netWorth: Double {
        accounts.filter { $0.type != .creditCard }.reduce(0) { $0 + $1.balance } +
        accounts.filter { $0.type == .creditCard }.reduce(0) { $0 + $1.balance }
    }

    var totalExpensesThisMonth: Double {
        let now = Date()
        return transactions
            .filter { $0.date.isThisMonth && $0.isExpense }
            .reduce(0) { $0 + $1.amount }
    }

    var totalIncomeThisMonth: Double {
        let now = Date()
        return transactions
            .filter { $0.date.isThisMonth && $0.isIncome }
            .reduce(0) { $0 + $1.amount }
    }

    var monthlyRecurringTotal: Double {
        recurringTransactions
            .filter { $0.isActive }
            .reduce(0) { $0 + $1.monthlyEquivalent }
    }

    // MARK: - Helper Methods
    func category(for id: UUID) -> Category? {
        categories.first { $0.id == id }
    }

    func account(for id: UUID) -> Account? {
        accounts.first { $0.id == id }
    }

    func transactionsForCategory(_ categoryId: UUID) -> [Transaction] {
        transactions.filter { $0.categoryId == categoryId }
    }

    func transactionsForAccount(_ accountId: UUID) -> [Transaction] {
        transactions.filter { $0.accountId == accountId }
    }

    func budgetForCategory(_ categoryId: UUID) -> Budget? {
        budgets.first { $0.categoryId == categoryId }
    }

    func groupedTransactions() -> [(String, [Transaction])] {
        let sorted = transactions.sorted { $0.date > $1.date }
        let grouped = Dictionary(grouping: sorted) { $0.dateGroupTitle }

        // Sort groups in logical order
        let groupOrder = ["Today", "Yesterday", "This Week", "This Month"]
        return grouped.sorted { groupOrder.contains($0.key) ? true : ($1.key > $0.key) }
    }

    // MARK: - CRUD Operations (Mock)
    func addTransaction(_ transaction: Transaction) {
        transactions.insert(transaction, at: 0)
        // Update account balance
        if let index = accounts.firstIndex(where: { $0.id == transaction.accountId }) {
            accounts[index].balance += transaction.amount
        }
    }

    func deleteTransaction(_ transaction: Transaction) {
        transactions.removeAll { $0.id == transaction.id }
        // Revert account balance
        if let index = accounts.firstIndex(where: { $0.id == transaction.accountId }) {
            accounts[index].balance -= transaction.amount
        }
    }

    func addAccount(_ account: Account) {
        accounts.append(account)
    }

    func deleteAccount(_ account: Account) {
        accounts.removeAll { $0.id == account.id }
    }

    func addGoal(_ goal: Goal) {
        goals.append(goal)
    }

    func updateGoal(_ goal: Goal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
        }
    }

    // MARK: - Budget Operations

    func addBudget(_ budget: Budget) {
        budgets.append(budget)
    }

    func updateBudget(_ budget: Budget) {
        if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
            var updatedBudget = budget
            updatedBudget.updatedAt = Date()
            budgets[index] = updatedBudget
        }
    }

    func deleteBudget(_ budget: Budget) {
        budgets.removeAll { $0.id == budget.id }
    }

    func deleteBudget(at id: UUID) {
        budgets.removeAll { $0.id == id }
    }

    func budget(for id: UUID) -> Budget? {
        budgets.first { $0.id == id }
    }

    func hasBudgetForCategory(_ categoryId: UUID) -> Bool {
        budgets.contains { $0.categoryId == categoryId }
    }

    func computeSpendingForCategory(_ categoryId: UUID, in month: Date) -> Double {
        let startOfMonth = month.startOfMonth
        let endOfMonth = month.endOfMonth

        return transactions
            .filter { transaction in
                transaction.date >= startOfMonth &&
                transaction.date <= endOfMonth &&
                transaction.categoryId == categoryId &&
                transaction.isExpense
            }
            .reduce(0) { $0 + abs($1.amount) }
    }

    func computeTotalSpending(in month: Date) -> Double {
        let startOfMonth = month.startOfMonth
        let endOfMonth = month.endOfMonth

        return transactions
            .filter { transaction in
                transaction.date >= startOfMonth &&
                transaction.date <= endOfMonth &&
                transaction.isExpense
            }
            .reduce(0) { $0 + abs($1.amount) }
    }

    // MARK: - Account Operations (Enhanced)

    func updateAccount(_ account: Account) {
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            var updatedAccount = account
            updatedAccount.updatedAt = Date()
            accounts[index] = updatedAccount
        }
    }

    func canDeleteAccount(_ account: Account) -> Bool {
        // Check if account has any transactions
        return !transactions.contains { $0.accountId == account.id }
    }

    /// Transfer money between accounts
    func transfer(from sourceAccount: Account, to destinationAccount: Account, amount: Double, notes: String?) {
        // Update source account balance
        if let sourceIndex = accounts.firstIndex(where: { $0.id == sourceAccount.id }) {
            accounts[sourceIndex].balance -= amount
        }

        // Update destination account balance
        if let destIndex = accounts.firstIndex(where: { $0.id == destinationAccount.id }) {
            accounts[destIndex].balance += amount
        }

        // Create transfer transactions (need transfer category)
        let transferCategory = categories.first { $0.name == "Transfer" } ?? categories[0]

        // Outgoing transaction from source
        let outgoingTransaction = Transaction(
            amount: -amount,
            categoryId: transferCategory.id,
            accountId: sourceAccount.id,
            date: Date(),
            payee: "Transfer to \(destinationAccount.name)",
            notes: notes
        )

        // Incoming transaction to destination
        let incomingTransaction = Transaction(
            amount: amount,
            categoryId: transferCategory.id,
            accountId: destinationAccount.id,
            date: Date(),
            payee: "Transfer from \(sourceAccount.name)",
            notes: notes
        )

        transactions.insert(outgoingTransaction, at: 0)
        transactions.insert(incomingTransaction, at: 0)

        // Post notification for balance changes
        NotificationCenter.default.post(name: .accountBalanceChanged, object: nil)
    }
}
