//
//  Account.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import Foundation
import SwiftUI

// MARK: - Account Type Enum
enum AccountType: String, CaseIterable, Codable {
    case checking = "Checking"
    case savings = "Savings"
    case creditCard = "Credit Card"
    case cash = "Cash"
    case investment = "Investment"

    var icon: String {
        switch self {
        case .checking: return "banknote"
        case .savings: return "piggybank"
        case .creditCard: return "creditcard"
        case .cash: return "banknotes"
        case .investment: return "chart.line.uptrend.xyaxis"
        }
    }

    var color: Color {
        switch self {
        case .checking: return .blue
        case .savings: return .green
        case .creditCard: return .orange
        case .cash: return .purple
        case .investment: return .cyan
        }
    }

    var isDebit: Bool {
        switch self {
        case .checking, .savings, .cash, .investment:
            return true
        case .creditCard:
            return false
        }
    }

    var isAsset: Bool {
        switch self {
        case .checking, .savings, .cash, .investment:
            return true
        case .creditCard:
            return false
        }
    }
}

// MARK: - Account Error
enum AccountError: LocalizedError {
    case hasTransactions
    case insufficientFunds
    case invalidAmount
    case sameAccount

    var errorDescription: String? {
        switch self {
        case .hasTransactions:
            return "Cannot delete account with existing transactions. Please delete transactions first or hide the account instead."
        case .insufficientFunds:
            return "Insufficient funds in source account."
        case .invalidAmount:
            return "Please enter a valid amount."
        case .sameAccount:
            return "Source and destination accounts must be different."
        }
    }
}

// MARK: - Account Model
struct Account: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var type: AccountType
    var balance: Double
    var currency: String
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    var icon: String?
    var institution: String?

    // New properties for world-class functionality
    var creditLimit: Double?
    var colorHex: String?
    var notes: String?
    var includeInNetWorth: Bool
    var includeInTotalBalance: Bool
    var accountNumber: String?  // Last 4 digits for display

    init(
        id: UUID = UUID(),
        name: String,
        type: AccountType,
        balance: Double,
        currency: String = "USD",
        isActive: Bool = true,
        institution: String? = nil,
        creditLimit: Double? = nil,
        colorHex: String? = nil,
        notes: String? = nil,
        includeInNetWorth: Bool = true,
        includeInTotalBalance: Bool = true,
        accountNumber: String? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.balance = balance
        self.currency = currency
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
        self.icon = type.icon
        self.institution = institution
        self.creditLimit = creditLimit
        self.colorHex = colorHex
        self.notes = notes
        self.includeInNetWorth = includeInNetWorth
        self.includeInTotalBalance = includeInTotalBalance
        self.accountNumber = accountNumber
    }

    // MARK: - Computed Properties

    var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: balance)) ?? "$0.00"
    }

    var isNegative: Bool {
        return balance < 0
    }

    var displayColor: Color {
        if let hex = colorHex, let color = Color(hex: hex) {
            return color
        }
        return type.color
    }

    var availableCredit: Double? {
        guard type == .creditCard, let limit = creditLimit else { return nil }
        return limit + balance  // balance is negative for credit cards
    }

    var isOverLimit: Bool {
        guard type == .creditCard, let limit = creditLimit else { return false }
        return abs(balance) > limit
    }

    var creditUtilization: Double? {
        guard type == .creditCard, let limit = creditLimit, limit > 0 else { return nil }
        return min(abs(balance) / limit, 1.0)
    }

    var formattedAccountNumber: String? {
        guard let number = accountNumber else { return nil }
        return "••••\(number.suffix(4))"
    }

    // MARK: - Equatable & Hashable

    static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Mock Data for Previews
extension Account {
    static var previewAccounts: [Account] {
        [
            Account(name: "Main Checking", type: .checking, balance: 3306.78, institution: "Chase Bank"),
            Account(name: "Emergency Fund", type: .savings, balance: 15000.00, institution: "Ally Bank"),
            Account(name: "Chase Sapphire", type: .creditCard, balance: -1200.00, institution: "Chase", creditLimit: 10000),
            Account(name: "Cash Wallet", type: .cash, balance: 150.00),
            Account(name: "401(k)", type: .investment, balance: 30000.00, institution: "Fidelity")
        ]
    }
}
