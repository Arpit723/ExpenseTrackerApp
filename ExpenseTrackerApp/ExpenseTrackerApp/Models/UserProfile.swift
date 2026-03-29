//
//  UserProfile.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import Foundation
import SwiftUI

enum AppTheme: String, CaseIterable, Codable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
}

struct NotificationSettings: Codable, Hashable {
    var dailyReminder: Bool
    var budgetAlerts: Bool
    var billReminders: Bool
    var weeklySummary: Bool
    var goalAchievements: Bool
    var newFeatures: Bool

    init(
        dailyReminder: Bool = true,
        budgetAlerts: Bool = true,
        billReminders: Bool = true,
        weeklySummary: Bool = true,
        goalAchievements: Bool = true,
        newFeatures: Bool = false
    ) {
        self.dailyReminder = dailyReminder
        self.budgetAlerts = budgetAlerts
        self.billReminders = billReminders
        self.weeklySummary = weeklySummary
        self.goalAchievements = goalAchievements
        self.newFeatures = newFeatures
    }
}

struct UserPreferences: Codable, Hashable {
    var currency: String
    var currencySymbol: String
    var firstDayOfWeek: Int
    var theme: AppTheme
    var language: String
    var notifications: NotificationSettings

    init(
        currency: String = "USD",
        currencySymbol: String = "$",
        firstDayOfWeek: Int = 2, // Monday = 2, Sunday = 1
        theme: AppTheme = .system,
        language: String = "en"
    ) {
        self.currency = currency
        self.currencySymbol = currencySymbol
        self.firstDayOfWeek = firstDayOfWeek
        self.theme = theme
        self.language = language
        self.notifications = NotificationSettings()
    }
}

struct UserProfile: Identifiable, Codable, Hashable {
    var id: UUID
    var displayName: String
    var email: String
    var avatarUrl: String?
    var preferences: UserPreferences
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        displayName: String,
        email: String,
        avatarUrl: String? = nil,
        preferences: UserPreferences = UserPreferences()
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.avatarUrl = avatarUrl
        self.preferences = preferences
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var initials: String {
        let names = displayName.split(separator: " ")
        if names.count >= 2 {
            let firstInitial = names[0].first.map { String($0) } ?? "U"
            let secondInitial = names[1].first.map { String($0) } ?? ""
            return firstInitial + secondInitial
        }
        return displayName.first.map { String($0) } ?? "U"
    }

    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
