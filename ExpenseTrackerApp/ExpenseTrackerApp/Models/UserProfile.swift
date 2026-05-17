//
//  UserProfile.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import Foundation

struct UserPreferences: Codable, Hashable {
  var currency: String
  var currencySymbol: String

  init(
    currency: String = "USD",
    currencySymbol: String = "$"
  ) {
    self.currency = currency
    self.currencySymbol = currencySymbol
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    currency = try container.decode(String.self, forKey: .currency)
    currencySymbol = try container.decode(String.self, forKey: .currencySymbol)
  }
}

struct UserProfile: Identifiable, Codable, Hashable {
  var id: UUID
  var uid: String?
  var email: String?
  var fullName: String?
  var birthDate: Date?
  var phone: String?
  var preferences: UserPreferences
  var createdAt: Date
  var updatedAt: Date

  init(
    id: UUID = UUID(),
    uid: String? = nil,
    email: String? = nil,
    fullName: String? = nil,
    birthDate: Date? = nil,
    phone: String? = nil,
    preferences: UserPreferences = UserPreferences()
  ) {
    self.id = id
    self.uid = uid
    self.email = email
    self.fullName = fullName
    self.birthDate = birthDate
    self.phone = phone
    self.preferences = preferences
    self.createdAt = Date()
    self.updatedAt = Date()
  }

  static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
    lhs.id == rhs.id && lhs.uid == rhs.uid && lhs.email == rhs.email && lhs.fullName == rhs.fullName
      && lhs.birthDate == rhs.birthDate && lhs.phone == rhs.phone
      && lhs.preferences == rhs.preferences
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
