//
//  FirestoreMigration.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 03/05/26.
//

import FirebaseFirestore
import Foundation

@MainActor
class FirestoreMigration {
  private let uid: String
  private let db = Firestore.firestore()
  private static let hasMigratedKey = "firestore_migration_v1_completed"

  init(uid: String) {
    self.uid = uid
  }

  func migrateIfNeeded() async throws {
    let key = "\(Self.hasMigratedKey)_\(uid)"
    guard !UserDefaults.standard.bool(forKey: key) else { return }
    try await migrateAutoIDDocuments()
    UserDefaults.standard.set(true, forKey: key)
  }

  func migrateAutoIDDocuments() async throws {
    let collection = db.collection("users").document(uid).collection("transactions")
    let snapshot = try await collection.getDocuments()

    for doc in snapshot.documents {
      guard let tx = try? doc.data(as: Transaction.self) else { continue }
      let expectedID = tx.id.uuidString

      if doc.documentID == expectedID { continue }

      try db.collection("users").document(uid).collection("transactions")
        .document(expectedID)
        .setData(from: tx)

      try await doc.reference.delete()
    }
  }
}
