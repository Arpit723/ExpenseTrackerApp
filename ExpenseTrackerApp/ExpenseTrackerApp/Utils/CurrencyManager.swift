//
//  CurrencyManager.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 10/05/26.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class CurrencyManager: ObservableObject {
  @Published var currencyCode: String {
    didSet { UserDefaults.standard.set(currencyCode, forKey: "currency") }
  }

  @Published var currencySymbol: String {
    didSet { UserDefaults.standard.set(currencySymbol, forKey: "currencySymbol") }
  }

  init() {
    self.currencyCode = UserDefaults.standard.string(forKey: "currency") ?? "USD"
    self.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "$"
  }

  func update(code: String, symbol: String) {
    currencyCode = code
    currencySymbol = symbol
  }
}
