//
//  Goal.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import Foundation
import SwiftUI

enum Priority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .orange
        case .high: return .red
        }
    }

    var icon: String {
        switch self {
        case .low: return "flag"
        case .medium: return "flag.fill"
        case .high: return "flame.fill"
        }
    }
}

struct Goal: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var targetAmount: Double
    var currentAmount: Double
    var targetDate: Date
    var priority: Priority
    var icon: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        targetAmount: Double,
        currentAmount: Double = 0,
        targetDate: Date,
        priority: Priority = .medium,
        icon: String = "star.fill"
    ) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.targetDate = targetDate
        self.priority = priority
        self.icon = icon
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var formattedTargetAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: targetAmount)) ?? "$0.00"
    }

    var formattedCurrentAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: currentAmount)) ?? "$0.00"
    }

    var formattedRemaining: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: remainingAmount)) ?? "$0.00"
    }

    var remainingAmount: Double {
        return targetAmount - currentAmount
    }

    var progressPercentage: Double {
        guard targetAmount > 0 else { return 0 }
        return min((currentAmount / targetAmount) * 100, 100)
    }

    var daysRemaining: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: targetDate)
        return max(components.day ?? 0, 0)
    }

    var isCompleted: Bool {
        return currentAmount >= targetAmount
    }

    var isOnTrack: Bool {
        guard daysRemaining > 0 else { return false }
        let dailyTarget = remainingAmount / Double(daysRemaining)
        return dailyTarget <= (targetAmount / 30) // Rough monthly target
    }

    var statusText: String {
        if isCompleted {
            return "Completed! 🎉"
        } else if isOnTrack {
            return "On track! ✅"
        } else {
            return "Behind schedule ⚠️"
        }
    }

    static func == (lhs: Goal, rhs: Goal) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
