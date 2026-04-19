//
//  FirestoreDataService.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 19/04/26.
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
class FirestoreDataService: ObservableObject, DataServiceProtocol {
    @Published var transactions: [Transaction] = []
    @Published var categories: [ExpenseTrackerApp.Category] = ExpenseTrackerApp.Category.defaultCategories
    @Published var userProfile: UserProfile?

    private let db = Firestore.firestore()
    private let uid: String
    private var listener: ListenerRegistration?

    // MARK: - Initialization
    init(uid: String) {
        self.uid = uid
    }

    deinit {
        listener?.remove()
    }

    // MARK: - Computed Properties
    var totalBalance: Double {
        transactions.reduce(0) { $0 + $1.amount }
    }

    var totalExpensesThisMonth: Double {
        transactions
            .filter { $0.date.isThisMonth && $0.isExpense }
            .reduce(0) { $0 + $1.amount }
    }

    var totalIncomeThisMonth: Double {
        transactions
            .filter { $0.date.isThisMonth && $0.isIncome }
            .reduce(0) { $0 + $1.amount }
    }

    // MARK: - Load Data
    func loadData() async throws {
        loadCategories()
        try await loadUserProfile()
        setupTransactionListener()
    }

    private func loadCategories() {
        categories = ExpenseTrackerApp.Category.defaultCategories
    }

    private func loadUserProfile() async throws {
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            if snapshot.exists {
                userProfile = try snapshot.data(as: UserProfile.self)
            }
        } catch {
            throw AppError.from(firebaseError: error)
        }
    }

    private func setupTransactionListener() {
        listener?.remove()
        listener = db.collection("users").document(uid).collection("transactions")
            .order(by: "date", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self, let snapshot else { return }
                var loaded: [Transaction] = []
                for doc in snapshot.documents {
                    if let tx = try? doc.data(as: Transaction.self) {
                        loaded.append(tx)
                    }
                }
                self.transactions = loaded
            }
    }

    // MARK: - Helper Methods
    func category(for id: UUID) -> ExpenseTrackerApp.Category? {
        categories.first { $0.id == id }
    }

    func groupedTransactions() -> [(String, [Transaction])] {
        let sorted = transactions.sorted { $0.date > $1.date }
        let grouped = Dictionary(grouping: sorted) { $0.dateGroupTitle }

        let groupOrder = ["Today", "Yesterday", "This Week", "This Month"]
        return grouped.sorted { pair1, pair2 in
            if let idx1 = groupOrder.firstIndex(of: pair1.key),
               let idx2 = groupOrder.firstIndex(of: pair2.key) {
                return idx1 < idx2
            }
            return pair1.key > pair2.key
        }
    }

    // MARK: - CRUD Operations
    func addTransaction(_ transaction: Transaction) async throws {
        do {
            let _ = try db.collection("users").document(uid).collection("transactions")
                .addDocument(from: transaction)
            NotificationCenter.default.post(name: .transactionAdded, object: transaction)
        } catch {
            throw AppError.from(firebaseError: error)
        }
    }

    func updateTransaction(_ transaction: Transaction) async throws {
        do {
            var updated = transaction
            updated.updatedAt = Date()
            try db.collection("users").document(uid).collection("transactions")
                .document(transaction.id.uuidString)
                .setData(from: updated)
            NotificationCenter.default.post(name: .transactionUpdated, object: updated)
        } catch {
            throw AppError.from(firebaseError: error)
        }
    }

    func deleteTransaction(_ transaction: Transaction) async throws {
        do {
            try await db.collection("users").document(uid).collection("transactions")
                .document(transaction.id.uuidString)
                .delete()
            NotificationCenter.default.post(name: .transactionDeleted, object: transaction)
        } catch {
            throw AppError.from(firebaseError: error)
        }
    }

    // MARK: - Batch Delete (for account deletion)
    func deleteAllTransactions() async throws {
        let collection = db.collection("users").document(uid).collection("transactions")
        var hasMore = true

        while hasMore {
            let snapshot = try await collection.limit(to: 500).getDocuments()
            guard !snapshot.documents.isEmpty else {
                hasMore = false
                break
            }

            let batch = db.batch()
            for doc in snapshot.documents {
                batch.deleteDocument(doc.reference)
            }
            try await batch.commit()

            hasMore = snapshot.documents.count >= 500
        }
    }

    func deleteUserProfile() async throws {
        try await db.collection("users").document(uid).delete()
    }
}
