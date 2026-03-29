//
//  Transaction.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import Foundation
import SwiftUI

struct Transaction: Identifiable, Codable, Hashable {
    var id: UUID
    var amount: Double
    var categoryId: UUID
    var accountId: UUID
    var date: Date
    var payee: String?
    var notes: String?
    var tags: [String]
    var receiptUrl: String?
    var isRecurring: Bool
    var location: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        amount: Double,
        categoryId: UUID,
        accountId: UUID,
        date: Date = Date(),
        payee: String? = nil,
        notes: String? = nil,
        tags: [String] = [],
        receiptUrl: String? = nil,
        isRecurring: Bool = false,
        location: String? = nil
    ) {
        self.id = id
        self.amount = amount
        self.categoryId = categoryId
        self.accountId = accountId
        self.date = date
        self.payee = payee
        self.notes = notes
        self.tags = tags
        self.receiptUrl = receiptUrl
        self.isRecurring = isRecurring
        self.location = location
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        let absAmount = abs(amount)
        return formatter.string(from: NSNumber(value: absAmount)) ?? "$0.00"
    }

    var isExpense: Bool {
        return amount < 0
    }

    var isIncome: Bool {
        return amount > 0
    }

    var displayAmount: String {
        let prefix = isExpense ? "-" : "+"
        return "\(prefix)\(formattedAmount)"
    }

    var amountColor: Color {
        return isExpense ? .red : .green
    }

    static func == (lhs: Transaction, rhs: Transaction) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Date Grouping
extension Transaction {
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(date)
    }

    var isThisWeek: Bool {
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }

    var isThisMonth: Bool {
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month)
    }

    var dateGroupTitle: String {
        if isToday {
            return "Today"
        } else if isYesterday {
            return "Yesterday"
        } else if isThisWeek {
            return "This Week"
        } else if isThisMonth {
            return "This Month"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        }
    }
}
