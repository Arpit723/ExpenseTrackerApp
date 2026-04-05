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
    var isSystem: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        color: String,
        isSystem: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
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

// MARK: - Default Categories (SRS v2.0 — 12 built-in)
extension Category {
    static var defaultCategories: [Category] {
        [
            Category(name: "Food & Dining", icon: "fork.knife", color: "#FF6B6B"),
            Category(name: "Transportation", icon: "car.fill", color: "#4ECDC4"),
            Category(name: "Shopping", icon: "bag.fill", color: "#45B7D1"),
            Category(name: "Entertainment", icon: "gamecontroller.fill", color: "#96CEB4"),
            Category(name: "Bills & Utilities", icon: "doc.text.fill", color: "#FFEAA7"),
            Category(name: "Health", icon: "heart.fill", color: "#DDA0DD"),
            Category(name: "Education", icon: "book.fill", color: "#98D8C8"),
            Category(name: "Travel", icon: "airplane", color: "#5DADE2"),
            Category(name: "Groceries", icon: "cart.fill", color: "#58D68D"),
            Category(name: "Other", icon: "square.grid.2x2.fill", color: "#BDC3C7"),
            Category(name: "Income", icon: "dollarsign.circle.fill", color: "#27AE60", isSystem: true),
            Category(name: "Transfer", icon: "arrow.left.arrow.right", color: "#85929E", isSystem: true)
        ]
    }
}
