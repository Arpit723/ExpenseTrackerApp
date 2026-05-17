//
//  SettingsViewModel.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import Combine
import Foundation

@MainActor
class SettingsViewModel: ObservableObject {
  // MARK: - Dependencies
  private let dataService: any DataServiceProtocol
  private let currencyManager: CurrencyManager

  // MARK: - Published Properties
  @Published var error: AppError?

  // MARK: - Debounce
  private var cancellables = Set<AnyCancellable>()
  private let syncSubject = PassthroughSubject<Void, Never>()

  // MARK: - Computed Properties
  var currentCurrency: (code: String, symbol: String) {
    get { (currencyManager.currencyCode, currencyManager.currencySymbol) }
    set {
      currencyManager.update(code: newValue.code, symbol: newValue.symbol)
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
  init(
    dataService: any DataServiceProtocol,
    currencyManager: CurrencyManager
  ) {
    self.dataService = dataService
    self.currencyManager = currencyManager
    syncSubject
      .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
      .sink { [weak self] in self?.performSync() }
      .store(in: &cancellables)
  }

  // MARK: - Firestore Settings Sync

  func syncFromFirestore() {
    guard let profile = dataService.userProfile else { return }
    let prefs = profile.preferences
    currencyManager.update(code: prefs.currency, symbol: prefs.currencySymbol)
  }

  func syncToFirestore() {
    syncSubject.send()
  }

  private func performSync() {
    guard let profile = dataService.userProfile else { return }
    var updated = profile
    updated.preferences = UserPreferences(
      currency: currencyManager.currencyCode,
      currencySymbol: currencyManager.currencySymbol
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
