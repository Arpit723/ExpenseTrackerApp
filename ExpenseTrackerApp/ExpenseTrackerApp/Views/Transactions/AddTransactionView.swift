//
//  AddTransactionView.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = TransactionViewModel()

    // Edit mode
    var editingTransaction: Transaction?

    // Form State
    @State private var amount: String = ""
    @State private var selectedCategory: Category?
    @State private var selectedAccount: Account?
    @State private var selectedDate = Date()
    @State private var payee: String = ""
    @State private var notes: String = ""
    @State private var isRecurring: Bool = false
    @State private var isExpense: Bool = true
    @State private var showingCategoryPicker: Bool = false
    @State private var showingAccountPicker: Bool = false

    // Computed Properties
    private var isEditMode: Bool {
        editingTransaction != nil
    }

    private var isValidForm: Bool {
        let amountValue = Double(amount) ?? 0
        return amountValue > 0 && selectedCategory != nil && selectedAccount != nil && !payee.isEmpty
    }

    // Initialize for add mode
    init() {
        self.editingTransaction = nil
    }

    // Initialize for edit mode
    init(transaction: Transaction) {
        self.editingTransaction = transaction
        _amount = State(initialValue: String(format: "%.2f", abs(transaction.amount)))
        _selectedDate = State(initialValue: transaction.date)
        _payee = State(initialValue: transaction.payee ?? "")
        _notes = State(initialValue: transaction.notes ?? "")
        _isRecurring = State(initialValue: transaction.isRecurring)
        _isExpense = State(initialValue: transaction.isExpense)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Amount Input
                    amountInputSection

                    // MARK: - Quick Amount Buttons
                    quickAmountButtons

                    // MARK: - Category Selection
                    categorySection

                    // MARK: - Account Selection
                    accountSection

                    // MARK: - Date Selection
                    dateSection

                    // MARK: - Payee
                    payeeSection

                    // MARK: - Notes
                    notesSection

                    // MARK: - Options
                    optionsSection

                    // MARK: - Save Button
                    saveButton
                }
                .padding(16)
            }
            .background(Color.appBackground)
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.appTextSecondary)
                }
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerSheet(categories: viewModel.categories, selectedCategory: $selectedCategory)
            }
            .sheet(isPresented: $showingAccountPicker) {
                AccountPickerSheet(accounts: viewModel.accounts, selectedAccount: $selectedAccount)
            }
        }
    }

    // MARK: - Amount Input
    private var amountInputSection: some View {
        VStack(spacing: 8) {
            Text("Amount")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("$")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(amount.isEmpty ? .appTextTertiary : .appTextPrimary)

                TextField("0.00", text: $amount)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.appTextPrimary)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(Color.appCardBackground)
            .cornerRadius(Constants.Layout.cardCornerRadius)
        }
    }

    // MARK: - Quick Amount Buttons
    private var quickAmountButtons: some View {
        VStack(spacing: 8) {
            Text("Quick Amounts")
                .font(.system(size: 13))
                .foregroundColor(.appTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                ForEach(Constants.quickAmounts, id: \.self) { value in
                    Button(action: {
                        amount = String(format: "%.0f", value)
                    }) {
                        Text("$\(Int(value))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.appPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.appPrimary.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }

    // MARK: - Category Section
    private var categorySection: some View {
        VStack(spacing: 8) {
            Text("Category")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: { showingCategoryPicker = true }) {
                HStack(spacing: 12) {
                    if let category = selectedCategory {
                        ZStack {
                            Circle()
                                .fill(category.swiftUIColor.opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: category.icon)
                                .font(.system(size: 16))
                                .foregroundColor(category.swiftUIColor)
                        }

                        Text(category.name)
                            .font(.system(size: 15))
                            .foregroundColor(.appTextPrimary)
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }

                        Text("Select a category")
                            .font(.system(size: 15))
                            .foregroundColor(.appTextTertiary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.appTextTertiary)
                }
                .padding(16)
                .background(Color.appCardBackground)
                .cornerRadius(Constants.Layout.cardCornerRadius)
            }
        }
    }

    // MARK: - Account Section
    private var accountSection: some View {
        VStack(spacing: 8) {
            Text("Account")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: { showingAccountPicker = true }) {
                HStack(spacing: 12) {
                    if let account = selectedAccount {
                        ZStack {
                            Circle()
                                .fill(account.type.color.opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: account.type.icon)
                                .font(.system(size: 16))
                                .foregroundColor(account.type.color)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.name)
                                .font(.system(size: 15))
                                .foregroundColor(.appTextPrimary)

                            Text("Balance: \(account.formattedBalance)")
                                .font(.system(size: 12))
                                .foregroundColor(.appTextSecondary)
                        }
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: "creditcard")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }

                        Text("Select an account")
                            .font(.system(size: 15))
                            .foregroundColor(.appTextTertiary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.appTextTertiary)
                }
                .padding(16)
                .background(Color.appCardBackground)
                .cornerRadius(Constants.Layout.cardCornerRadius)
            }
        }
    }

    // MARK: - Date Section
    private var dateSection: some View {
        VStack(spacing: 8) {
            Text("Date")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appCardBackground)
                .cornerRadius(Constants.Layout.cardCornerRadius)
        }
    }

    // MARK: - Payee Section
    private var payeeSection: some View {
        VStack(spacing: 8) {
            Text("Payee / Merchant")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                Image(systemName: "person.circle")
                    .foregroundColor(.appTextTertiary)

                TextField("e.g., Starbucks, Amazon", text: $payee)
                    .font(.system(size: 15))
            }
            .padding(16)
            .background(Color.appCardBackground)
            .cornerRadius(Constants.Layout.cardCornerRadius)
        }
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(spacing: 8) {
            Text("Notes (Optional)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                Image(systemName: "note.text")
                    .foregroundColor(.appTextTertiary)

                TextField("Add a note...", text: $notes)
                    .font(.system(size: 15))
            }
            .padding(16)
            .background(Color.appCardBackground)
            .cornerRadius(Constants.Layout.cardCornerRadius)
        }
    }

    // MARK: - Options Section
    private var optionsSection: some View {
        VStack(spacing: 0) {
            // Receipt Button
            Button(action: {}) {
                HStack {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.appPrimary)

                    Text("Attach Receipt")
                        .font(.system(size: 15))
                        .foregroundColor(.appTextPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.appTextTertiary)
                }
                .padding(16)
            }

            Divider()
                .padding(.horizontal, 16)

            // Recurring Toggle
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.appPrimary)

                Text("Mark as Recurring")
                    .font(.system(size: 15))
                    .foregroundColor(.appTextPrimary)

                Spacer()

                Toggle("", isOn: $isRecurring)
                    .labelsHidden()
            }
            .padding(16)
        }
        .background(Color.appCardBackground)
        .cornerRadius(Constants.Layout.cardCornerRadius)
    }

    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveTransaction) {
            Text("Save Transaction")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: isValidForm ? [Color.appPrimary, Color.appSecondary] : [Color.gray, Color.gray]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(Constants.Layout.cardCornerRadius)
        }
        .disabled(!isValidForm)
    }

    // MARK: - Actions
    private func saveTransaction() {
        guard let amountValue = Double(amount),
              let category = selectedCategory,
              let account = selectedAccount else { return }

        let transaction = Transaction(
            amount: -amountValue, // Negative for expenses
            categoryId: category.id,
            accountId: account.id,
            date: selectedDate,
            payee: payee,
            notes: notes.isEmpty ? nil : notes,
            isRecurring: isRecurring
        )

        viewModel.addTransaction(transaction)
        dismiss()
    }
}

// MARK: - Category Picker Sheet
struct CategoryPickerSheet: View {
    let categories: [Category]
    @Binding var selectedCategory: Category?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(categories.filter { !$0.isSystem }) { category in
                        CategoryIconView(
                            category: category,
                            isSelected: selectedCategory?.id == category.id
                        )
                        .onTapGesture {
                            selectedCategory = category
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Account Picker Sheet
struct AccountPickerSheet: View {
    let accounts: [Account]
    @Binding var selectedAccount: Account?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(AccountType.allCases, id: \.self) { type in
                    let accountsOfType = accounts.filter { $0.type == type && $0.isActive }
                    if !accountsOfType.isEmpty {
                        Section(header: Text(type.rawValue)) {
                            ForEach(accountsOfType) { account in
                                Button(action: {
                                    selectedAccount = account
                                    dismiss()
                                }) {
                                    HStack {
                                        Image(systemName: account.type.icon)
                                            .foregroundColor(account.type.color)
                                            .frame(width: 24)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(account.name)
                                                .foregroundColor(.appTextPrimary)

                                            Text(account.formattedBalance)
                                                .font(.system(size: 12))
                                                .foregroundColor(account.isNegative ? .red : .appTextSecondary)
                                        }

                                        Spacer()

                                        if selectedAccount?.id == account.id {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.appPrimary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Select Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Preview
#Preview {
    AddTransactionView()
}
