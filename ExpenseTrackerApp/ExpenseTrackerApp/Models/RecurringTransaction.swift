//
//  RecurringTransaction.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import Foundation
import SwiftUI

enum Frequency: String, CaseIterable, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    case custom = "Custom"

    var icon: String {
        switch self {
        case .daily: return "sun.max"
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        case .yearly: return "calendar.circle"
        case .custom: return "slider.horizontal.3"
        }
    }
}

struct RecurringTransaction: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var amount: Double
    var categoryId: UUID
    var accountId: UUID
    var frequency: Frequency
    var nextDueDate: Date
    var isActive: Bool
    var autoCreate: Bool
    var startDate: Date
    var endDate: Date?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        categoryId: UUID,
        accountId: UUID,
        frequency: Frequency = .monthly,
        nextDueDate: Date,
        isActive: Bool = true,
        autoCreate: Bool = true,
        startDate: Date = Date(),
        endDate: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.categoryId = categoryId
        self.accountId = accountId
        self.frequency = frequency
        self.nextDueDate = nextDueDate
        self.isActive = isActive
        self.autoCreate = autoCreate
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: abs(amount))) ?? "$0.00"
    }

    var isExpense: Bool {
        return amount < 0
    }

    var daysUntilDue: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: nextDueDate)
        return max(components.day ?? 0, 0)
    }

    var dueStatusText: String {
        if daysUntilDue == 0 {
            return "Due today"
        } else if daysUntilDue == 1 {
            return "Due tomorrow"
        } else {
            return "Due in \(daysUntilDue) days"
        }
    }

    var monthlyEquivalent: Double {
        switch frequency {
        case .daily:
            return amount * 30
        case .weekly:
            return amount * 4
        case .monthly:
            return amount
        case .yearly:
            return amount / 12
        case .custom:
            return amount
        }
    }

    static func == (lhs: RecurringTransaction, rhs: RecurringTransaction) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
