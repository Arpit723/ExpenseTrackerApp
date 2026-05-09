//
//  DataServiceContainer.swift
//  ExpenseTrackerApp
//

import Foundation

@MainActor
class DataServiceContainer: ObservableObject {
  @Published var service: any DataServiceProtocol

  init(service: any DataServiceProtocol = DataService.shared) {
    self.service = service
  }

  func switchToFirestore(uid: String) {
    service = FirestoreDataService(uid: uid)
  }

  func switchToLocal() {
    service = DataService.shared
  }
}
