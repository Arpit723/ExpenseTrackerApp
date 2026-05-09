//
//  SettingsViewModel.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import Combine
import Foundation
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
  // MARK: - App Storage
  @AppStorage("appTheme") var appTheme: String = AppTheme.system.rawValue
  @AppStorage("currency") var currency: String = "USD"
  @AppStorage("currencySymbol") var currencySymbol: String = "$"

  // MARK: - Dependencies
  private let dataService: any DataServiceProtocol

  // MARK: - Published Properties
  @Published var error: AppError?

  // MARK: - Debounce
  private var cancellables = Set<AnyCancellable>()
  private let syncSubject = PassthroughSubject<Void, Never>()

  // MARK: - Computed Properties
  var currentTheme: AppTheme {
    get { AppTheme(rawValue: appTheme) ?? .system }
    set {
      appTheme = newValue.rawValue
      syncToFirestore()
    }
  }

  var currentCurrency: (code: String, symbol: String) {
    get { (currency, currencySymbol) }
    set {
      currency = newValue.code
      currencySymbol = newValue.symbol
      syncToFirestore()
    }
  }

  // Available currencies (FR-4.1)
  let availableCurrencies: [(code: String, symbol: String, name: String)] = [
    ("USD", "$", "US Dollar"),
    ("EUR", "€", "Euro"),
    ("GBP", "£", "British Pound"),
    ("JPY", "¥", "Japanese Yen"),
    ("CAD", "$", "Canadian Dollar"),
    ("AUD", "$", "Australian Dollar"),
    ("INR", "₹", "Indian Rupee"),
    ("CNY", "¥", "Chinese Yuan"),
    ("CHF", "CHF", "Swiss Franc"),
    ("MXN", "$", "Mexican Peso"),
    ("SGD", "$", "Singapore Dollar"),
    ("HKD", "$", "Hong Kong Dollar"),
  ]

  // MARK: - Initialization
  init(dataService: any DataServiceProtocol = DataService.shared) {
    self.dataService = dataService
    syncSubject
      .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
      .sink { [weak self] in self?.performSync() }
      .store(in: &cancellables)
  }

  // MARK: - Firestore Settings Sync

  func syncFromFirestore() {
    guard let profile = dataService.userProfile else { return }
    let prefs = profile.preferences
    currency = prefs.currency
    currencySymbol = prefs.currencySymbol
    appTheme = prefs.theme.rawValue
  }

  func syncToFirestore() {
    syncSubject.send()
  }

  private func performSync() {
    guard let profile = dataService.userProfile else { return }
    var updated = profile
    updated.preferences = UserPreferences(
      currency: currency,
      currencySymbol: currencySymbol,
      theme: AppTheme(rawValue: appTheme) ?? .system
    )
    Task {
      do {
        try await dataService.updateUserProfile(updated)
      } catch {
        self.error = error as? AppError ?? .data(.saveFailed)
      }
    }
  }
}
