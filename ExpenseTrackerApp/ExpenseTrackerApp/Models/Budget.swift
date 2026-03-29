//
//  Budget.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import Foundation
import SwiftUI

// MARK: - Budget Period
enum BudgetPeriod: String, CaseIterable, Codable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    case custom = "Custom"

    var icon: String {
        switch self {
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        case .yearly: return "calendar.circle"
        case .custom: return "slider.horizontal.3"
        }
    }

    var displayName: String {
        return rawValue
    }
}

// MARK: - Budget Model
struct Budget: Identifiable, Codable, Hashable {
    var id: UUID
    var categoryId: UUID?
    var amount: Double
    var period: BudgetPeriod
    var rollover: Bool
    var rolloverAmount: Double  // Carried over from previous period
    var startDate: Date
    var endDate: Date?
    var actualSpent: Double
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        categoryId: UUID? = nil,
        amount: Double,
        period: BudgetPeriod = .monthly,
        rollover: Bool = false,
        rolloverAmount: Double = 0,
        startDate: Date = Date(),
        endDate: Date? = nil,
        actualSpent: Double = 0
    ) {
        self.id = id
        self.categoryId = categoryId
        self.amount = amount
        self.period = period
        self.rollover = rollover
        self.rolloverAmount = rolloverAmount
        self.startDate = startDate
        self.endDate = endDate
        self.actualSpent = actualSpent
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Type Checks

    var isOverallBudget: Bool {
        return categoryId == nil
    }

    var isCategoryBudget: Bool {
        return categoryId != nil
    }

    // MARK: - Validation

    var isValid: Bool {
        return amount > 0 && startDate <= (endDate ?? Date.distantFuture)
    }

    // MARK: - Computed Amounts

    /// Total budget including rollover from previous period
    var effectiveBudget: Double {
        return amount + rolloverAmount
    }

    /// Remaining amount (can be negative when over budget)
    var remainingAmount: Double {
        return effectiveBudget - actualSpent
    }

    /// Absolute remaining amount (always positive)
    var absoluteRemaining: Double {
        return abs(remainingAmount)
    }

    // MARK: - Formatted Strings

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    var formattedSpent: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: actualSpent)) ?? "$0.00"
    }

    var formattedRemaining: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: remainingAmount)) ?? "$0.00"
    }

    var formattedRemainingAbsolute: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: absoluteRemaining)) ?? "$0.00"
    }

    var formattedEffectiveBudget: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: effectiveBudget)) ?? "$0.00"
    }

    var formattedRollover: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: rolloverAmount)) ?? "$0.00"
    }

    // MARK: - Progress & Status

    var progressPercentage: Double {
        guard effectiveBudget > 0 else { return 0 }
        return min(abs(actualSpent / effectiveBudget) * 100, 100)
    }

    var rawProgressPercentage: Double {
        // Can exceed 100% for display purposes
        guard effectiveBudget > 0 else { return 0 }
        return (actualSpent / effectiveBudget) * 100
    }

    var isOverBudget: Bool {
        return actualSpent > effectiveBudget
    }

    var overBudgetAmount: Double {
        return max(0, actualSpent - effectiveBudget)
    }

    var formattedOverBudgetAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: overBudgetAmount)) ?? "$0.00"
    }

    var progressColor: Color {
        if isOverBudget {
            return .red
        } else if progressPercentage >= 90 {
            return .red
        } else if progressPercentage >= 75 {
            return .orange
        } else {
            return .green
        }
    }

    var statusIcon: String {
        if isOverBudget {
            return "exclamationmark.triangle.fill"
        } else if progressPercentage >= 90 {
            return "flame.fill"
        } else if progressPercentage >= 75 {
            return "bolt.fill"
        } else {
            return "checkmark.circle.fill"
        }
    }

    var statusText: String {
        if isOverBudget {
            return "Over budget by \(formattedOverBudgetAmount)"
        } else if progressPercentage >= 90 {
            return "Almost at limit"
        } else if progressPercentage >= 75 {
            return "Watch spending"
        } else {
            return "On track"
        }
    }

    var hasRollover: Bool {
        return rollover && rolloverAmount != 0
    }

    var rolloverDescription: String {
        if rolloverAmount > 0 {
            return "+\(formattedRollover) carried over"
        } else if rolloverAmount < 0 {
            return "\(formattedRollover) overspent from last month"
        } else {
            return "No rollover"
        }
    }

    // MARK: - Equatable & Hashable

    static func == (lhs: Budget, rhs: Budget) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Preview Mock Data
extension Budget {
    static var previewBudgets: [Budget] {
        let now = Date()
        return [
            Budget(
                amount: 5000.00,
                period: .monthly,
                startDate: now.startOfMonth,
                actualSpent: 3847.00
            ),
            Budget(
                categoryId: UUID(),
                amount: 500.00,
                period: .monthly,
                rollover: true,
                rolloverAmount: 50.0,
                startDate: now.startOfMonth,
                actualSpent: 420.00
            ),
            Budget(
                categoryId: UUID(),
                amount: 300.00,
                period: .monthly,
                startDate: now.startOfMonth,
                actualSpent: 180.00
            ),
            Budget(
                categoryId: UUID(),
                amount: 500.00,
                period: .monthly,
                startDate: now.startOfMonth,
                actualSpent: 650.00  // Over budget
            )
        ]
    }
}
