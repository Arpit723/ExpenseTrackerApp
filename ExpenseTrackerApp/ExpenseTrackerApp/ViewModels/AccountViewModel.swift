//
//  AccountViewModel.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Account ViewModel
@MainActor
class AccountViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var accounts: [Account] = []
    @Published var filteredAccounts: [Account] = []
    @Published var searchText: String = ""
    @Published var selectedType: AccountType?
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var showingError: Bool = false

    // MARK: - Dependencies
    let dataService: MockDataService  // Made internal for access in views
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    /// Net worth including all accounts marked for inclusion
    var netWorth: Double {
        accounts
            .filter { $0.includeInNetWorth }
            .reduce(0) { $0 + $1.balance }
    }

    /// Total of all positive balance accounts
    var totalAssets: Double {
        accounts
            .filter { $0.balance > 0 && $0.includeInNetWorth }
            .reduce(0) { $0 + $1.balance }
    }

    /// Total of all negative balance accounts (liabilities)
    var totalLiabilities: Double {
        accounts
            .filter { $0.balance < 0 && $0.includeInNetWorth }
            .reduce(0) { $0 + $1.balance }
    }

    /// Total balance for accounts marked for inclusion
    var totalBalance: Double {
        accounts
            .filter { $0.includeInTotalBalance }
            .reduce(0) { $0 + $1.balance }
    }

    /// Grouped accounts by type
    var groupedAccounts: [(AccountType, [Account])] {
        AccountType.allCases.compactMap { type in
            let accountsOfType = filteredAccounts.filter { $0.type == type }
            return accountsOfType.isEmpty ? nil : (type, accountsOfType)
        }
    }

    /// Active accounts count
    var activeAccountsCount: Int {
        accounts.filter { $0.isActive }.count
    }

    /// Accounts available for transfers (active accounts)
    var transferableAccounts: [Account] {
        accounts.filter { $0.isActive }
    }

    // MARK: - Initialization
    init(dataService: MockDataService = .shared) {
        self.dataService = dataService
        setupBindings()
        loadAccounts()
    }

    // MARK: - Setup
    private func setupBindings() {
        // Combine search and type filter into a single pipeline
        Publishers.CombineLatest($searchText, $selectedType)
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading

    func loadAccounts() {
        isLoading = true
        accounts = dataService.accounts
        applyFilters()
        isLoading = false
    }

    func refreshAccounts() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 300_000_000)
        loadAccounts()
    }

    // MARK: - CRUD Operations

    /// Add a new account
    func addAccount(_ account: Account) {
        dataService.addAccount(account)
        loadAccounts()
        NotificationCenter.default.post(name: .accountAdded, object: account)
    }

    /// Update an existing account
    func updateAccount(_ account: Account) {
        if let index = dataService.accounts.firstIndex(where: { $0.id == account.id }) {
            var updatedAccount = account
            updatedAccount.updatedAt = Date()
            dataService.accounts[index] = updatedAccount
        }
        loadAccounts()
        NotificationCenter.default.post(name: .accountUpdated, object: account)
    }

    /// Delete an account with validation
    func deleteAccount(_ account: Account) throws {
        // Check if account has transactions
        let hasTransactions = dataService.transactions.contains { $0.accountId == account.id }
        if hasTransactions {
            throw AccountError.hasTransactions
        }

        dataService.deleteAccount(account)
        loadAccounts()
        NotificationCenter.default.post(name: .accountDeleted, object: account)
    }

    /// Delete account at index set (for swipe-to-delete)
    func deleteAccount(at offsets: IndexSet, in groupIndex: Int) {
        let group = groupedAccounts[groupIndex]
        for index in offsets {
            let account = group.1[index]
            do {
                try deleteAccount(account)
            } catch {
                self.error = error
                self.showingError = true
            }
        }
    }

    /// Adjust account balance
    func adjustBalance(for account: Account, newBalance: Double) {
        var updatedAccount = account
        updatedAccount.balance = newBalance
        updatedAccount.updatedAt = Date()
        updateAccount(updatedAccount)
    }

    /// Toggle account active status
    func toggleAccountActive(_ account: Account) {
        var updatedAccount = account
        updatedAccount.isActive.toggle()
        updatedAccount.updatedAt = Date()
        updateAccount(updatedAccount)
    }

    /// Toggle include in net worth
    func toggleIncludeInNetWorth(_ account: Account) {
        var updatedAccount = account
        updatedAccount.includeInNetWorth.toggle()
        updatedAccount.updatedAt = Date()
        updateAccount(updatedAccount)
    }

    // MARK: - Transfer Operations

    /// Transfer money between accounts
    func transfer(from sourceAccount: Account, to destinationAccount: Account, amount: Double, notes: String?) throws {
        // Validation
        guard amount > 0 else {
            throw AccountError.invalidAmount
        }

        guard sourceAccount.id != destinationAccount.id else {
            throw AccountError.sameAccount
        }

        // Check sufficient funds for debit accounts
        if sourceAccount.type.isDebit && sourceAccount.balance < amount {
            throw AccountError.insufficientFunds
        }

        // Perform transfer via data service
        dataService.transfer(from: sourceAccount, to: destinationAccount, amount: amount, notes: notes)
        loadAccounts()
    }

    // MARK: - Filtering

    private func applyFilters() {
        var result = accounts

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { account in
                let nameMatch = account.name.localizedCaseInsensitiveContains(searchText)
                let institutionMatch = account.institution?.localizedCaseInsensitiveContains(searchText) ?? false
                return nameMatch || institutionMatch
            }
        }

        // Apply type filter
        if let selectedType = selectedType {
            result = result.filter { $0.type == selectedType }
        }

        filteredAccounts = result
    }

    func clearFilters() {
        searchText = ""
        selectedType = nil
    }

    // MARK: - Helper Methods

    func account(for id: UUID) -> Account? {
        accounts.first { $0.id == id }
    }

    func category(for id: UUID) -> Category? {
        dataService.category(for: id)
    }

    func transactionsForAccount(_ accountId: UUID) -> [Transaction] {
        dataService.transactionsForAccount(accountId)
    }

    func transactionsForAccount(_ accountId: UUID, filteredBy filter: TransactionFilter) -> [Transaction] {
        let transactions = dataService.transactionsForAccount(accountId)

        switch filter {
        case .all:
            return transactions
        case .expenses:
            return transactions.filter { $0.isExpense }
        case .income:
            return transactions.filter { $0.isIncome }
        case .transfers:
            return transactions.filter { dataService.category(for: $0.categoryId)?.name == "Transfer" }
        }
    }

    // MARK: - Statistics

    /// Spending this month for an account
    func spendingThisMonth(for accountId: UUID) -> Double {
        dataService.transactionsForAccount(accountId)
            .filter { $0.date.isThisMonth && $0.isExpense }
            .reduce(0) { $0 + abs($1.amount) }
    }

    /// Income this month for an account
    func incomeThisMonth(for accountId: UUID) -> Double {
        dataService.transactionsForAccount(accountId)
            .filter { $0.date.isThisMonth && $0.isIncome }
            .reduce(0) { $0 + $1.amount }
    }

    /// Transaction count for an account
    func transactionCount(for accountId: UUID) -> Int {
        dataService.transactionsForAccount(accountId).count
    }

    /// Average transaction amount for an account
    func averageTransaction(for accountId: UUID) -> Double {
        let transactions = dataService.transactionsForAccount(accountId)
        guard !transactions.isEmpty else { return 0 }
        let total = transactions.reduce(0) { $0 + abs($1.amount) }
        return total / Double(transactions.count)
    }

    /// Spending trend for last 7 days
    func spendingTrendLast7Days(for accountId: UUID) -> [Double] {
        let calendar = Calendar.current
        let today = Date()
        var trend: [Double] = []

        for i in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let daySpending = dataService.transactionsForAccount(accountId)
                .filter { calendar.isDate($0.date, inSameDayAs: date) && $0.isExpense }
                .reduce(0) { $0 + abs($1.amount) }
            trend.append(daySpending)
        }

        return trend
    }

    /// Last transaction for an account
    func lastTransaction(for accountId: UUID) -> Transaction? {
        dataService.transactionsForAccount(accountId)
            .sorted { $0.date > $1.date }
            .first
    }
}

// MARK: - Transaction Filter (shared across views)
enum TransactionFilter: String, CaseIterable {
    case all = "All"
    case expenses = "Expenses"
    case income = "Income"
    case transfers = "Transfers"

    var title: String {
        return self.rawValue
    }
}

// MARK: - Notification Names Extension
extension Notification.Name {
    static let accountAdded = Notification.Name("accountAdded")
    static let accountUpdated = Notification.Name("accountUpdated")
    static let accountDeleted = Notification.Name("accountDeleted")
}
