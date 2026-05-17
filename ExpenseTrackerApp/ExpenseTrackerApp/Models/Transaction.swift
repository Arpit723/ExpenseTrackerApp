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
  var date: Date
  var payee: String?
  var notes: String?
  var createdAt: Date
  var updatedAt: Date

  init(
    id: UUID = UUID(),
    amount: Double,
    categoryId: UUID,
    date: Date = Date(),
    payee: String? = nil,
    notes: String? = nil
  ) {
    self.id = id
    self.amount = amount
    self.categoryId = categoryId
    self.date = date
    self.payee = payee
    self.notes = notes
    self.createdAt = Date()
    self.updatedAt = Date()
  }

  func formattedAmount(
    currencyCode: String = UserDefaults.standard.string(forKey: "currency") ?? "USD"
  ) -> String {
    abs(amount).formattedAsCurrency(code: currencyCode)
  }

  var isExpense: Bool {
    return amount < 0
  }

  var isIncome: Bool {
    return amount > 0
  }

  func displayAmount(
    currencyCode: String = UserDefaults.standard.string(forKey: "currency") ?? "USD"
  ) -> String {
    let prefix = isExpense ? "-" : "+"
    return "\(prefix)\(formattedAmount(currencyCode: currencyCode))"
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
      return "Older"
    }
  }
}

// MARK: - Array Grouping
extension [Transaction] {
  func groupedByDate() -> [(String, [Transaction])] {
    let sorted = self.sorted { $0.date > $1.date }
    let grouped = Dictionary(grouping: sorted) { $0.dateGroupTitle }
    let groupOrder = ["Today", "Yesterday", "This Week", "This Month"]
    return grouped.sorted { pair1, pair2 in
      if let idx1 = groupOrder.firstIndex(of: pair1.key),
        let idx2 = groupOrder.firstIndex(of: pair2.key)
      {
        return idx1 < idx2
      }
      return pair1.key > pair2.key
    }
  }
}
