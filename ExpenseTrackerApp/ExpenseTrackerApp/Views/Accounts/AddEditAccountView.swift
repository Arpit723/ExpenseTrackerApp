//
//  AddEditAccountView.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

// MARK: - Add/Edit Account View
struct AddEditAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AccountViewModel()

    // Edit mode
    let editingAccount: Account?

    // Form state
    @State private var name: String = ""
    @State private var selectedType: AccountType = .checking
    @State private var balance: String = ""
    @State private var institution: String = ""
    @State private var creditLimit: String = ""
    @State private var notes: String = ""
    @State private var selectedColorHex: String?
    @State private var includeInNetWorth: Bool = true
    @State private var includeInTotalBalance: Bool = true
    @State private var accountNumber: String = ""

    // UI state
    @State private var showColorPicker: Bool = false
    @State private var showValidationError: Bool = false
    @State private var validationMessage: String = ""

    // Focus state
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case name, balance, institution, creditLimit, notes, accountNumber
    }

    // Color options
    private let colorOptions: [(name: String, hex: String)] = [
        ("Blue", "#007AFF"),
        ("Green", "#34C759"),
        ("Orange", "#FF9500"),
        ("Purple", "#AF52DE"),
        ("Pink", "#FF2D55"),
        ("Red", "#FF3B30"),
        ("Teal", "#5AC8FA"),
        ("Indigo", "#5856D6")
    ]

    var isEditMode: Bool {
        editingAccount != nil
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !balance.isEmpty &&
        Double(balance) != nil
    }

    init(account: Account? = nil) {
        self.editingAccount = account
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Account Type Section
                accountTypeSection

                // MARK: - Account Details Section
                accountDetailsSection

                // MARK: - Balance Section
                balanceSection

                // MARK: - Appearance Section
                appearanceSection

                // MARK: - Options Section
                optionsSection
            }
            .navigationTitle(isEditMode ? "Edit Account" : "Add Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditMode ? "Update" : "Save") {
                        saveAccount()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .onAppear {
                loadEditingData()
            }
            .alert("Validation Error", isPresented: $showValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
        }
    }

    // MARK: - Account Type Section
    private var accountTypeSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AccountType.allCases, id: \.self) { type in
                        accountTypeButton(type)
                    }
                }
                .padding(.vertical, 8)
            }
        } header: {
            Text("Account Type")
        }
    }

    private func accountTypeButton(_ type: AccountType) -> some View {
        Button {
            selectedType = type
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(selectedType == type ? type.color : type.color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: type.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(selectedType == type ? .white : type.color)
                }

                Text(type.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(selectedType == type ? .appTextPrimary : .appTextSecondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Account Details Section
    private var accountDetailsSection: some View {
        Section("Account Details") {
            TextField("Account Name", text: $name)
                .focused($focusedField, equals: .name)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .institution
                }

            TextField("Institution (Optional)", text: $institution)
                .focused($focusedField, equals: .institution)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = selectedType == .creditCard ? .creditLimit : .balance
                }

            TextField("Last 4 Digits (Optional)", text: $accountNumber)
                .focused($focusedField, equals: .accountNumber)
                .keyboardType(.numberPad)
                .onChange(of: accountNumber) { _, newValue in
                    accountNumber = String(newValue.prefix(4))
                }

            TextField("Notes (Optional)", text: $notes, axis: .vertical)
                .focused($focusedField, equals: .notes)
                .lineLimit(2...4)
        }
    }

    // MARK: - Balance Section
    private var balanceSection: some View {
        Section {
            HStack {
                Text("Current Balance")
                    .foregroundColor(.appTextSecondary)
                Spacer()
                TextField("0.00", text: $balance)
                    .focused($focusedField, equals: .balance)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 17, weight: .medium))
            }

            if selectedType == .creditCard {
                HStack {
                    Text("Credit Limit")
                        .foregroundColor(.appTextSecondary)
                    Spacer()
                    TextField("0.00", text: $creditLimit)
                        .focused($focusedField, equals: .creditLimit)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 17, weight: .medium))
                }

                if let limit = Double(creditLimit), limit > 0,
                   let currentBalance = Double(balance) {
                    let available = limit + currentBalance
                    HStack {
                        Text("Available Credit")
                            .font(.system(size: 13))
                            .foregroundColor(.appTextSecondary)
                        Spacer()
                        Text(available.formattedAsCurrency())
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(available >= 0 ? .appSuccess : .appDanger)
                    }
                }
            }
        } header: {
            Text("Balance")
        } footer: {
            if selectedType == .creditCard {
                Text("Enter credit card balance as a negative number (e.g., -1200.00)")
            }
        }
    }

    // MARK: - Appearance Section
    private var appearanceSection: some View {
        Section("Appearance") {
            // Preview Card
            previewCard

            // Color Selection
            colorSelectionRow
        }
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview")
                .font(.system(size: 13))
                .foregroundColor(.appTextSecondary)

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(previewColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: selectedType.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(previewColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(name.isEmpty ? "Account Name" : name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.appTextPrimary)

                    if !institution.isEmpty {
                        Text(institution)
                            .font(.system(size: 12))
                            .foregroundColor(.appTextSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(previewBalance)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(previewBalanceColor)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var previewColor: Color {
        if let hex = selectedColorHex, let color = Color(hex: hex) {
            return color
        }
        return selectedType.color
    }

    private var previewBalance: String {
        guard let amount = Double(balance) else {
            return "$0.00"
        }
        return amount.formattedAsCurrency()
    }

    private var previewBalanceColor: Color {
        guard let amount = Double(balance) else {
            return .appTextPrimary
        }
        return amount < 0 ? .red : .appTextPrimary
    }

    private var colorSelectionRow: some View {
        HStack {
            Text("Custom Color")
                .foregroundColor(.appTextSecondary)

            Spacer()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // None option (use default)
                    Button {
                        selectedColorHex = nil
                    } label: {
                        Circle()
                            .strokeBorder(Color.gray, lineWidth: selectedColorHex == nil ? 2 : 0)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.gray)
                                    .opacity(selectedColorHex == nil ? 1 : 0)
                            )
                    }

                    ForEach(colorOptions, id: \.hex) { option in
                        Button {
                            selectedColorHex = option.hex
                        } label: {
                            Circle()
                                .fill(Color(hex: option.hex) ?? .gray)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.white, lineWidth: selectedColorHex == option.hex ? 2 : 0)
                                )
                                .shadow(color: selectedColorHex == option.hex ? Color.black.opacity(0.2) : .clear, radius: 2)
                        }
                    }
                }
            }
            .frame(width: 260)
        }
    }

    // MARK: - Options Section
    private var optionsSection: some View {
        Section {
            Toggle("Include in Net Worth", isOn: $includeInNetWorth)

            Toggle("Include in Total Balance", isOn: $includeInTotalBalance)
        } header: {
            Text("Options")
        } footer: {
            Text("Accounts included in net worth will be counted toward your overall financial position.")
        }
    }

    // MARK: - Actions

    private func loadEditingData() {
        guard let account = editingAccount else { return }

        name = account.name
        selectedType = account.type
        balance = String(account.balance)
        institution = account.institution ?? ""
        creditLimit = account.creditLimit != nil ? String(account.creditLimit!) : ""
        notes = account.notes ?? ""
        selectedColorHex = account.colorHex
        includeInNetWorth = account.includeInNetWorth
        includeInTotalBalance = account.includeInTotalBalance
        accountNumber = account.accountNumber ?? ""
    }

    private func saveAccount() {
        guard let balanceValue = Double(balance) else {
            validationMessage = "Please enter a valid balance."
            showValidationError = true
            return
        }

        let creditLimitValue = selectedType == .creditCard ? Double(creditLimit) : nil

        if let existingAccount = editingAccount {
            // Update existing account
            var updated = existingAccount
            updated.name = name.trimmingCharacters(in: .whitespaces)
            updated.type = selectedType
            updated.balance = balanceValue
            updated.institution = institution.isEmpty ? nil : institution
            updated.creditLimit = creditLimitValue
            updated.notes = notes.isEmpty ? nil : notes
            updated.colorHex = selectedColorHex
            updated.includeInNetWorth = includeInNetWorth
            updated.includeInTotalBalance = includeInTotalBalance
            updated.accountNumber = accountNumber.isEmpty ? nil : accountNumber
            updated.updatedAt = Date()

            viewModel.updateAccount(updated)
        } else {
            // Create new account
            let newAccount = Account(
                name: name.trimmingCharacters(in: .whitespaces),
                type: selectedType,
                balance: balanceValue,
                institution: institution.isEmpty ? nil : institution,
                creditLimit: creditLimitValue,
                colorHex: selectedColorHex,
                notes: notes.isEmpty ? nil : notes,
                includeInNetWorth: includeInNetWorth,
                includeInTotalBalance: includeInTotalBalance,
                accountNumber: accountNumber.isEmpty ? nil : accountNumber
            )

            viewModel.addAccount(newAccount)
        }

        dismiss()
    }
}

// MARK: - Preview
#Preview("Add Account") {
    AddEditAccountView()
}

#Preview("Edit Account") {
    AddEditAccountView(account: Account.previewAccounts[0])
}
