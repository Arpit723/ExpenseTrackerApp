//
//  Double+Currency.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import Foundation

extension Double {
  // MARK: - Static NumberFormatter (avoid per-call allocation)

  private static let currencyFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "USD"
    return formatter
  }()

  func formattedAsCurrency(code: String = UserDefaults.standard.string(forKey: "currency") ?? "USD")
    -> String
  {
    Self.currencyFormatter.currencyCode = code
    return Self.currencyFormatter.string(from: NSNumber(value: self)) ?? "$0.00"
  }

  var absValue: Double {
    return abs(self)
  }

  var isPositive: Bool {
    return self >= 0
  }

  var isNegative: Bool {
    return self < 0
  }

  var percentage: String {
    return String(format: "%.1f%%", self)
  }
}
