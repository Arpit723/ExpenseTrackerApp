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

struct UserPreferences: Codable, Hashable {
    var currency: String
    var currencySymbol: String
    var theme: AppTheme

    init(
        currency: String = "USD",
        currencySymbol: String = "$",
        theme: AppTheme = .system
    ) {
        self.currency = currency
        self.currencySymbol = currencySymbol
        self.theme = theme
    }
}

struct UserProfile: Identifiable, Codable, Hashable {
    var id: UUID
    var preferences: UserPreferences
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        preferences: UserPreferences = UserPreferences()
    ) {
        self.id = id
        self.preferences = preferences
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
