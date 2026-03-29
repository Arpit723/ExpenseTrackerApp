//
//  BudgetViewModel.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Budget Health Status
enum BudgetHealthStatus: Equatable {
    case healthy(Int)
    case warning(Int)
    case critical(Int)

    var color: Color {
        switch self {
        case .healthy: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }

    var icon: String {
        switch self {
        case .healthy: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }

    var title: String {
        switch self {
        case .healthy(let count): return "\(count) On Track"
        case .warning(let count): return "\(count) Near Limit"
        case .critical(let count): return "\(count) Over Budget"
        }
    }

    var message: String {
        switch self {
        case .healthy:
            return "Great job! All your category budgets are on track."
        case .warning:
            return "Some categories are approaching their limits."
        case .critical:
            return "You've exceeded budget in some categories."
        }
    }
}

// MARK: - Budget ViewModel
@MainActor
class BudgetViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var budgets: [Budget] = []
    @Published var selectedMonth: Date = Date()
    @Published var isLoading: Bool = false
    @Published var error: BudgetError?
    @Published var showingError: Bool = false
    @Published var showingAddBudget: Bool = false
    @Published var editingBudget: Budget?

    // MARK: - Dependencies
    private let dataService: MockDataService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    /// Overall budget for selected month
    var overallBudget: Budget? {
        budgets.first { $0.isOverallBudget }
    }

    /// Category budgets for selected month
    var categoryBudgets: [Budget] {
        budgets.filter { $0.isCategoryBudget }
    }

    /// Total budget amount across all categories
    var totalCategoryBudgets: Double {
        categoryBudgets.reduce(0) { $0 + $1.amount }
    }

    /// Total spent across all categories
    var totalCategorySpent: Double {
        categoryBudgets.reduce(0) { $0 + $1.actualSpent }
    }

    /// Total remaining across all categories
    var totalCategoryRemaining: Double {
        categoryBudgets.reduce(0) { $0 + $1.remainingAmount }
    }

    /// Categories without budgets (excluding system categories)
    var categoriesWithoutBudget: [Category] {
        let budgetedCategoryIds = Set(categoryBudgets.compactMap { $0.categoryId })
        return dataService.categories.filter { category in
            !budgetedCategoryIds.contains(category.id) && !category.isSystem
        }
    }

    /// Budget health status
    var budgetHealthStatus: BudgetHealthStatus {
        let overBudgetCount = categoryBudgets.filter { $0.isOverBudget }.count
        let nearLimitCount = categoryBudgets.filter { !$0.isOverBudget && $0.progressPercentage >= 75 }.count
        let healthyCount = categoryBudgets.filter { $0.progressPercentage < 75 }.count

        if overBudgetCount > 0 {
            return .critical(overBudgetCount)
        } else if nearLimitCount > 0 {
            return .warning(nearLimitCount)
        } else {
            return .healthy(healthyCount)
        }
    }

    // MARK: - Month Navigation

    var monthYearString: String {
        selectedMonth.formatted(with: "MMMM yyyy")
    }

    var isCurrentMonth: Bool {
        Calendar.current.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    var isFutureMonth: Bool {
        selectedMonth.startOfMonth > Date().startOfMonth
    }

    var isPastMonth: Bool {
        selectedMonth.startOfMonth < Date().startOfMonth
    }

    // MARK: - Statistics

    var averageDailySpending: Double {
        let calendar = Calendar.current
        let daysInMonth = calendar.dateComponents([.day], from: selectedMonth.startOfMonth, to: Date()).day ?? 1
        let days = max(daysInMonth, 1)
        return totalCategorySpent / Double(days)
    }

    var projectedMonthlySpending: Double {
        let calendar = Calendar.current
        let daysInMonth = selectedMonth.daysInMonth
        let dayOfMonth = selectedMonth.dayOfMonth

        guard dayOfMonth > 0 else { return 0 }
        return averageDailySpending * Double(daysInMonth)
    }

    var projectedRemaining: Double {
        (overallBudget?.amount ?? totalCategoryBudgets) - projectedMonthlySpending
    }

    // MARK: - Initialization

    init(dataService: MockDataService = .shared) {
        self.dataService = dataService
        setupBindings()
        loadBudgets()
    }

    // MARK: - Setup Bindings

    private func setupBindings() {
        // Listen for transaction changes to recalculate spending
        NotificationCenter.default
            .publisher(for: .transactionAdded)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.recalculateAllSpending() }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: .transactionDeleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.recalculateAllSpending() }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: .transactionUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.recalculateAllSpending() }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading

    func loadBudgets() {
        isLoading = true
        budgets = dataService.budgets
        recalculateAllSpending()
        calculateRollovers()
        isLoading = false
    }

    func refreshBudgets() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 300_000_000)
        loadBudgets()
    }

    // MARK: - Month Navigation

    func navigateToPreviousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = newDate
            loadBudgetsForMonth()
        }
    }

    func navigateToNextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = newDate
            loadBudgetsForMonth()
        }
    }

    func navigateToCurrentMonth() {
        selectedMonth = Date()
        loadBudgetsForMonth()
    }

    private func loadBudgetsForMonth() {
        calculateRollovers()
        recalculateAllSpending()
    }

    // MARK: - Spending Calculation

    private func recalculateAllSpending() {
        let startOfMonth = selectedMonth.startOfMonth
        let endOfMonth = selectedMonth.endOfMonth

        for i in budgets.indices {
            let budget = budgets[i]
            let spending = computeSpending(for: budget, from: startOfMonth, to: endOfMonth)
            budgets[i].actualSpent = spending
        }

        // Sync back to dataService
        syncBudgetsToDataService()
    }

    private func computeSpending(for budget: Budget, from startDate: Date, to endDate: Date) -> Double {
        let transactions = dataService.transactions

        if budget.isOverallBudget {
            // Overall budget: sum all expenses for the month
            return transactions
                .filter { transaction in
                    transaction.date >= startDate &&
                    transaction.date <= endDate &&
                    transaction.isExpense
                }
                .reduce(0) { $0 + abs($1.amount) }
        } else if let categoryId = budget.categoryId {
            // Category budget: sum expenses for this category
            return transactions
                .filter { transaction in
                    transaction.date >= startDate &&
                    transaction.date <= endDate &&
                    transaction.categoryId == categoryId &&
                    transaction.isExpense
                }
                .reduce(0) { $0 + abs($1.amount) }
        }
        return 0
    }

    // MARK: - Rollover Calculation

    private func calculateRollovers() {
        let calendar = Calendar.current
        guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) else { return }

        let previousStartOfMonth = previousMonth.startOfMonth
        let previousEndOfMonth = previousMonth.endOfMonth

        for i in budgets.indices {
            var budget = budgets[i]

            if budget.rollover && !budget.isOverallBudget {
                // Calculate previous month's spending for this budget
                let previousSpent = computeSpending(for: budget, from: previousStartOfMonth, to: previousEndOfMonth)
                let previousRemaining = budget.amount - previousSpent

                // Rollover can be positive (extra to spend) or negative (reduced budget)
                budget.rolloverAmount = previousRemaining
            } else {
                budget.rolloverAmount = 0
            }

            budgets[i] = budget
        }

        syncBudgetsToDataService()
    }

    // MARK: - CRUD Operations

    /// Add a new budget
    func addBudget(categoryId: UUID?, amount: Double, rollover: Bool = false) throws {
        // Validation
        guard amount > 0 else {
            throw BudgetError.invalidAmount
        }

        // Check for duplicate category budget (only for category budgets, not overall)
        if let categoryId = categoryId {
            let exists = budgets.contains { $0.categoryId == categoryId }
            if exists {
                throw BudgetError.categoryAlreadyHasBudget
            }
        }

        let budget = Budget(
            categoryId: categoryId,
            amount: amount,
            period: .monthly,
            rollover: rollover,
            startDate: selectedMonth.startOfMonth
        )

        dataService.budgets.append(budget)
        loadBudgets()
        NotificationCenter.default.post(name: .budgetUpdated, object: budget)
    }

    /// Update an existing budget
    func updateBudget(_ budget: Budget) throws {
        guard budget.amount > 0 else {
            throw BudgetError.invalidAmount
        }

        guard let index = dataService.budgets.firstIndex(where: { $0.id == budget.id }) else {
            throw BudgetError.budgetNotFound
        }

        var updatedBudget = budget
        updatedBudget.updatedAt = Date()
        dataService.budgets[index] = updatedBudget
        loadBudgets()
        NotificationCenter.default.post(name: .budgetUpdated, object: updatedBudget)
    }

    /// Delete a budget
    func deleteBudget(_ budget: Budget) throws {
        // Prevent deleting overall budget
        if budget.isOverallBudget {
            throw BudgetError.cannotDeleteOverallBudget
        }

        dataService.budgets.removeAll { $0.id == budget.id }
        loadBudgets()
        NotificationCenter.default.post(name: .budgetUpdated, object: nil)
    }

    /// Delete budgets at index set (for swipe-to-delete)
    func deleteBudget(at offsets: IndexSet) {
        let budgetsToDelete = offsets.map { categoryBudgets[$0] }
        for budget in budgetsToDelete {
            do {
                try deleteBudget(budget)
            } catch {
                self.error = error as? BudgetError
                self.showingError = true
            }
        }
    }

    // MARK: - Helper Methods

    func budget(for categoryId: UUID) -> Budget? {
        budgets.first { $0.categoryId == categoryId }
    }

    func category(for budget: Budget) -> Category? {
        guard let categoryId = budget.categoryId else { return nil }
        return dataService.category(for: categoryId)
    }

    func canAddBudget(for categoryId: UUID) -> Bool {
        return !budgets.contains { $0.categoryId == categoryId }
    }

    private func syncBudgetsToDataService() {
        dataService.budgets = budgets
    }

    // MARK: - Error Handling

    func showError(_ error: BudgetError) {
        self.error = error
        self.showingError = true
    }

    func dismissError() {
        self.error = nil
        self.showingError = false
    }
}

// MARK: - Budget Creation Helper
extension BudgetViewModel {

    /// Create a quick budget for a category
    func createQuickBudget(for category: Category, amount: Double) {
        do {
            try addBudget(categoryId: category.id, amount: amount, rollover: false)
        } catch {
            showError(error as? BudgetError ?? .invalidAmount)
        }
    }

    /// Duplicate budgets from previous month
    func copyBudgetsFromPreviousMonth() {
        let calendar = Calendar.current
        guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) else { return }

        // This would typically fetch previous month budgets and create copies
        // For now, we'll just recalculate
        loadBudgets()
    }
}
