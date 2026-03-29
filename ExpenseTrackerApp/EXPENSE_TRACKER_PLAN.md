# Expense Tracker - Budget Feature Implementation Plan

## Executive Summary
This plan implements a complete Budget CRUD system with month navigation that properly computes spending from transactions.

---

## Phase 1: Model Layer Fixes

### 1.1 Fix Budget.swift Model

**Changes Required:**
```swift
struct Budget {
    // ... existing properties ...

    // NEW: Track rollover amount from previous period
    var rolloverAmount: Double = 0.0

    // FIX: Computed remaining should show absolute value
    var remainingAmount: Double {
        return amount + rolloverAmount - actualSpent
    }

    // NEW: Formatted remaining (handles negative gracefully)
    var formattedRemainingAbsolute: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: abs(remainingAmount))) ?? "$0.00"
    }

    // NEW: Total budget including rollover
    var effectiveBudget: Double {
        return amount + rolloverAmount
    }

    // NEW: Validation
    var isValid: Bool {
        return amount > 0 && startDate <= (endDate ?? Date.distantFuture)
    }
}
```

### 1.2 Create BudgetError Enum

```swift
enum BudgetError: LocalizedError {
    case invalidAmount
    case categoryAlreadyHasBudget
    case categoryNotFound
    case cannotDeleteOverallBudget
    case invalidDateRange

    var errorDescription: String? {
        switch self {
        case .invalidAmount: return "Budget amount must be greater than zero"
        case .categoryAlreadyHasBudget: return "A budget already exists for this category"
        case .categoryNotFound: return "Category not found"
        case .cannotDeleteOverallBudget: return "Cannot delete the overall budget"
        case .invalidDateRange: return "End date must be after start date"
        }
    }
}
```

---

## Phase 2: ViewModel Layer

### 2.1 Create BudgetViewModel.swift

**Full Implementation:**

```swift
@MainActor
class BudgetViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var budgets: [Budget] = []
    @Published var selectedMonth: Date = Date()
    @Published var isLoading: Bool = false
    @Published var error: BudgetError?
    @Published var showingError: Bool = false

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
        budgets.filter { !$0.isOverallBudget }
    }

    /// Total budget amount across all categories
    var totalCategoryBudgets: Double {
        categoryBudgets.reduce(0) { $0 + $1.amount }
    }

    /// Total spent across all categories
    var totalCategorySpent: Double {
        categoryBudgets.reduce(0) { $0 + $1.actualSpent }
    }

    /// Categories without budgets
    var categoriesWithoutBudget: [Category] {
        let budgetedCategoryIds = Set(categoryBudgets.compactMap { $0.categoryId })
        return dataService.categories.filter { !budgetedCategoryIds.contains($0.id) && !$0.isSystem }
    }

    // MARK: - Month Navigation

    var monthYearString: String {
        selectedMonth.formatted(with: "MMMM yyyy")
    }

    var isCurrentMonth: Bool {
        Calendar.current.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    var isFutureMonth: Bool {
        selectedMonth > Date()
    }

    // MARK: - Initialization

    init(dataService: MockDataService = .shared) {
        self.dataService = dataService
        setupBindings()
        loadBudgets()
    }

    private func setupBindings() {
        // Listen for transaction changes to recalculate spending
        NotificationCenter.default
            .publisher(for: .transactionAdded)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.recalculateSpending() }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: .transactionDeleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.recalculateSpending() }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: .transactionUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.recalculateSpending() }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading

    func loadBudgets() {
        isLoading = true
        budgets = dataService.budgets
        recalculateSpending()
        isLoading = false
    }

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
        // For each budget, compute rollover from previous month
        calculateRollovers()
        recalculateSpending()
    }

    // MARK: - Spending Calculation

    private func recalculateSpending() {
        let calendar = Calendar.current
        let startOfMonth = selectedMonth.startOfMonth
        let endOfMonth = selectedMonth.endOfMonth

        for i in 0..<budgets.indices {
            let budget = budgets[i]

            // Calculate spending for this category in the selected month
            let spending: Double
            if budget.isOverallBudget {
                // Overall budget: sum all expenses for the month
                spending = dataService.transactions
                    .filter { transaction in
                        transaction.date >= startOfMonth &&
                        transaction.date <= endOfMonth &&
                        transaction.isExpense
                    }
                    .reduce(0) { $0 + abs($1.amount) }
            } else if let categoryId = budget.categoryId {
                // Category budget: sum expenses for this category
                spending = dataService.transactions
                    .filter { transaction in
                        transaction.date >= startOfMonth &&
                        transaction.date <= endOfMonth &&
                        transaction.categoryId == categoryId &&
                        transaction.isExpense
                    }
                    .reduce(0) { $0 + abs($1.amount) }
            } else {
                spending = 0
            }

            budgets[i].actualSpent = spending
        }

        // Sync back to dataService
        dataService.budgets = budgets
    }

    private func calculateRollovers() {
        // Get previous month budgets
        let calendar = Calendar.current
        guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) else { return }

        for i in 0..<budgets.indices {
            var budget = budgets[i]

            if budget.rollover {
                // Get previous month's remaining amount
                let previousSpent = computeSpending(for: budget, in: previousMonth)
                let previousRemaining = budget.amount - previousSpent

                // Positive remaining = extra to spend, negative = reduced budget
                budget.rolloverAmount = previousRemaining
            } else {
                budget.rolloverAmount = 0
            }

            budgets[i] = budget
        }
    }

    private func computeSpending(for budget: Budget, in month: Date) -> Double {
        let startOfMonth = month.startOfMonth
        let endOfMonth = month.endOfMonth

        if budget.isOverallBudget {
            return dataService.transactions
                .filter { $0.date >= startOfMonth && $0.date <= endOfMonth && $0.isExpense }
                .reduce(0) { $0 + abs($1.amount) }
        } else if let categoryId = budget.categoryId {
            return dataService.transactions
                .filter { $0.date >= startOfMonth && $0.date <= endOfMonth && $0.categoryId == categoryId && $0.isExpense }
                .reduce(0) { $0 + abs($1.amount) }
        }
        return 0
    }

    // MARK: - CRUD Operations

    /// Add a new category budget
    func addBudget(categoryId: UUID?, amount: Double, rollover: Bool = false) throws {
        // Validation
        guard amount > 0 else {
            throw BudgetError.invalidAmount
        }

        // Check for duplicate category budget
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
            return
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

    /// Delete budget at index
    func deleteBudget(at indexSet: IndexSet) {
        for index in indexSet {
            let budget = categoryBudgets[index]
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

    // MARK: - Statistics

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
}

// MARK: - Supporting Types

enum BudgetHealthStatus {
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
        case .critical: return "xmark.circle.fill"
        }
    }

    var message: String {
        switch self {
        case .healthy(let count): return "\(count) categories on track"
        case .warning(let count): return "\(count) categories near limit"
        case .critical(let count): return "\(count) categories over budget"
        }
    }
}
```

---

## Phase 3: View Layer

### 3.1 Create AddBudgetView.swift

```swift
struct AddBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: BudgetViewModel

    @State private var selectedCategory: Category?
    @State private var amount: String = ""
    @State private var rollover: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    let isOverallBudget: Bool

    init(viewModel: BudgetViewModel, isOverallBudget: Bool = false) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.isOverallBudget = isOverallBudget
    }

    var body: some View {
        NavigationStack {
            Form {
                // Category Selection (skip for overall budget)
                if !isOverallBudget {
                    Section("Category") {
                        Picker("Category", selection: $selectedCategory) {
                            Text("Select a category").tag(nil as Category?)
                            ForEach(viewModel.categoriesWithoutBudget) { category in
                                HStack {
                                    Image(systemName: category.icon)
                                    Text(category.name)
                                }.tag(category as Category?)
                            }
                        }
                    }
                }

                // Amount
                Section("Budget Amount") {
                    HStack {
                        Text("$")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $amount)
                            .font(.title)
                            .keyboardType(.decimalPad)
                    }
                }

                // Rollover Option
                Section {
                    Toggle("Rollover unused budget", isOn: $rollover)
                    Text("Unused budget will carry over to next month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(isOverallBudget ? "Set Overall Budget" : "Add Category Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveBudget() }
                        .disabled(!isValid)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else { return false }
        if !isOverallBudget && selectedCategory == nil { return false }
        return true
    }

    private func saveBudget() {
        guard let amountValue = Double(amount), amountValue > 0 else { return }

        do {
            try viewModel.addBudget(
                categoryId: isOverallBudget ? nil : selectedCategory?.id,
                amount: amountValue,
                rollover: rollover
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
```

### 3.2 Create EditBudgetView.swift

```swift
struct EditBudgetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: BudgetViewModel

    @State private var budget: Budget
    @State private var amount: String = ""
    @State private var rollover: Bool = false

    init(viewModel: BudgetViewModel, budget: Budget) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _budget = State(initialValue: budget)
        self._amount = State(initialValue: String(format: "%.0f", budget.amount))
        self._rollover = State(initialValue: budget.rollover)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Category Info (read-only)
                if let category = viewModel.category(for: budget) {
                    Section("Category") {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(category.swiftUIColor)
                            Text(category.name)
                                .font(.headline)
                        }
                    }
                }

                // Amount
                Section("Budget Amount") {
                    HStack {
                        Text("$")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $amount)
                            .font(.title)
                            .keyboardType(.decimalPad)
                    }
                }

                // Rollover
                Section {
                    Toggle("Rollover unused budget", isOn: $rollover)
                }

                // Stats
                Section("This Month") {
                    LabeledContent("Spent", value: budget.formattedSpent)
                    LabeledContent("Remaining", value: budget.formattedRemaining)
                    LabeledContent("Progress", value: "\(Int(budget.progressPercentage))%")
                }
            }
            .navigationTitle("Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveBudget() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else { return false }
        return true
    }

    private func saveBudget() {
        guard let amountValue = Double(amount), amountValue > 0 else { return }

        var updatedBudget = budget
        updatedBudget.amount = amountValue
        updatedBudget.rollover = rollover

        do {
            try viewModel.updateBudget(updatedBudget)
            dismiss()
        } catch {
            // Handle error
        }
    }
}
```

### 3.3 Update BudgetView.swift

**Key Changes:**
- Use `BudgetViewModel` instead of `MockDataService` directly
- Connect `.sheet` for AddBudgetView
- Add EditBudgetView on tap
- Month navigation now triggers data reload

---

## Phase 4: MockDataService Updates

### 4.1 Add Budget CRUD to MockDataService

```swift
// MARK: - Budget Operations
func addBudget(_ budget: Budget) {
    budgets.append(budget)
}

func updateBudget(_ budget: Budget) {
    if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
        budgets[index] = budget
    }
}

func deleteBudget(_ budget: Budget) {
    budgets.removeAll { $0.id == budget.id }
}

func budgetForCategory(_ categoryId: UUID) -> Budget? {
    budgets.first { $0.categoryId == categoryId }
}

func computeSpendingForCategory(_ categoryId: UUID, in month: Date) -> Double {
    let startOfMonth = month.startOfMonth
    let endOfMonth = month.endOfMonth

    return transactions
        .filter { $0.date >= startOfMonth && $0.date <= endOfMonth && $0.categoryId == categoryId && $0.isExpense }
        .reduce(0) { $0 + abs($1.amount) }
}
```

---

## Phase 5: Testing Checklist

### Unit Tests
- [ ] BudgetViewModel.monthNavigation_updatesSpendingData
- [ ] BudgetViewModel.addBudget_validatesAmount
- [ ] BudgetViewModel.addBudget_preventsDuplicateCategory
- [ ] BudgetViewModel.deleteBudget_preventsOverallBudgetDeletion
- [ ] BudgetViewModel.rollover_carriesPreviousMonthRemainder

### Integration Tests
- [ ] Transaction added → Budget spending recalculated
- [ ] Transaction deleted → Budget spending recalculated
- [ ] Month navigation → Correct spending for that month

### Edge Cases
- [ ] Zero amount budget → Validation error
- [ ] Category deleted → Budget handling
- [ ] Future month → Empty spending, rollover calculated
- [ ] Rollover with overspend → Reduces next month's budget

---

## Implementation Order

1. **Fix Budget.swift** - Model fixes (formattedRemaining, rolloverAmount)
2. **Create BudgetError.swift** - Error handling
3. **Create BudgetViewModel.swift** - Core business logic
4. **Update MockDataService** - Add budget CRUD methods
5. **Create AddBudgetView.swift** - Add functionality
6. **Create EditBudgetView.swift** - Edit functionality
7. **Update BudgetView.swift** - Connect ViewModel and sheets
8. **Test thoroughly**

---

## Files to Create/Modify

| File | Action | Priority |
|------|--------|----------|
| `Models/Budget.swift` | MODIFY | P0 |
| `Models/BudgetError.swift` | CREATE | P0 |
| `ViewModels/BudgetViewModel.swift` | CREATE | P0 |
| `Services/MockDataService.swift` | MODIFY | P0 |
| `Views/Budget/AddBudgetView.swift` | CREATE | P1 |
| `Views/Budget/EditBudgetView.swift` | CREATE | P1 |
| `Views/Budget/BudgetView.swift` | MODIFY | P1 |

---

*Plan created: 2026-03-28*
*Status: Ready for implementation*
