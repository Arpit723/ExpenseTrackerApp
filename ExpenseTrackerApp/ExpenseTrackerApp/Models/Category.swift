//
//  Category.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import Foundation
import SwiftUI

struct Category: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var icon: String
    var color: String
    var parentId: UUID?
    var budget: Double?
    var isSystem: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        color: String,
        parentId: UUID? = nil,
        budget: Double? = nil,
        isSystem: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.parentId = parentId
        self.budget = budget
        self.isSystem = isSystem
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var displayName: String {
        return name
    }

    var swiftUIColor: Color {
        Color(hex: color) ?? .gray
    }

    static func == (lhs: Category, rhs: Category) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Default Categories
extension Category {
    static var defaultCategories: [Category] {
        [
            Category(name: "Food & Drinks", icon: "fork.knife", color: "#FF6B6B", budget: 500),
            Category(name: "Transportation", icon: "car.fill", color: "#4ECDC4", budget: 300),
            Category(name: "Shopping", icon: "bag.fill", color: "#45B7D1", budget: 400),
            Category(name: "Entertainment", icon: "film.fill", color: "#96CEB4", budget: 200),
            Category(name: "Bills & Utilities", icon: "bolt.fill", color: "#FFEAA7", budget: 250),
            Category(name: "Healthcare", icon: "cross.case.fill", color: "#DDA0DD", budget: 150),
            Category(name: "Education", icon: "book.fill", color: "#98D8C8", budget: 100),
            Category(name: "Personal Care", icon: "scissors", color: "#F7DC6F", budget: 75),
            Category(name: "Gifts & Donations", icon: "gift.fill", color: "#BB8FCE", budget: 100),
            Category(name: "Groceries", icon: "cart.fill", color: "#58D68D", budget: 400),
            Category(name: "Travel", icon: "airplane", color: "#5DADE2", budget: 200),
            Category(name: "Income", icon: "dollarsign.circle.fill", color: "#27AE60", isSystem: true),
            Category(name: "Transfer", icon: "arrow.left.arrow.right", color: "#85929E", isSystem: true),
            Category(name: "Other", icon: "questionmark.circle", color: "#BDC3C7", budget: 100)
        ]
    }
}
