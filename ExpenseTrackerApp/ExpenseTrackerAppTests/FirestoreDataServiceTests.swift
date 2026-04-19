//
//  FirestoreDataServiceTests.swift
//  ExpenseTrackerAppTests
//
//  Created by Arpit Parekh on 19/04/26.
//
//  Requires Firestore Emulator running on localhost:8080
//  Start with: firebase emulators:start
//

import XCTest
import FirebaseFirestore
@testable import ExpenseTrackerApp

@MainActor
final class FirestoreDataServiceTests: XCTestCase {

    private var dataService: FirestoreDataService!
    private let testUID = "test-user-\(UUID().uuidString.prefix(8))"

    override func setUp() async throws {
        try await super.setUp()
        let settings = Firestore.firestore().settings
        settings.host = "localhost:8080"
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings

        dataService = FirestoreDataService(uid: testUID)
    }

    override func tearDown() async throws {
        // Clean up test data
        let db = Firestore.firestore()
        let snapshot = try? await db.collection("users").document(testUID).collection("transactions").getDocuments()
        for doc in snapshot?.documents ?? [] {
            try? await doc.reference.delete()
        }
        try? await db.collection("users").document(testUID).delete()
        dataService = nil
        try await super.tearDown()
    }

    // MARK: - CRUD

    func testAddTransaction() async throws {
        let categoryId = ExpenseTrackerApp.Category.defaultCategories[0].id
        let transaction = Transaction(amount: -50.0, categoryId: categoryId, payee: "Test Store")

        try await dataService.addTransaction(transaction)

        // Verify in Firestore directly
        let db = Firestore.firestore()
        let snapshot = try await db.collection("users").document(testUID).collection("transactions").getDocuments()
        XCTAssertEqual(snapshot.documents.count, 1)

        let fetched = try snapshot.documents.first?.data(as: Transaction.self)
        XCTAssertEqual(fetched?.amount, -50.0)
        XCTAssertEqual(fetched?.payee, "Test Store")
    }

    func testUpdateTransaction() async throws {
        let categoryId = ExpenseTrackerApp.Category.defaultCategories[0].id
        let transaction = Transaction(amount: -25.0, categoryId: categoryId)
        try await dataService.addTransaction(transaction)

        var updated = transaction
        updated.amount = -30.0
        try await dataService.updateTransaction(updated)

        let db = Firestore.firestore()
        let doc = try await db.collection("users").document(testUID).collection("transactions")
            .document(transaction.id.uuidString).getDocument()
        let fetched = try doc.data(as: Transaction.self)
        XCTAssertEqual(fetched.amount, -30.0)
    }

    func testDeleteTransaction() async throws {
        let categoryId = ExpenseTrackerApp.Category.defaultCategories[0].id
        let transaction = Transaction(amount: -10.0, categoryId: categoryId)
        try await dataService.addTransaction(transaction)

        try await dataService.deleteTransaction(transaction)

        let db = Firestore.firestore()
        let snapshot = try await db.collection("users").document(testUID).collection("transactions").getDocuments()
        XCTAssertTrue(snapshot.documents.isEmpty)
    }

    // MARK: - Computed Properties

    func testTotalBalance() async throws {
        let cat0 = ExpenseTrackerApp.Category.defaultCategories[0].id
        let cat10 = ExpenseTrackerApp.Category.defaultCategories[10].id

        try await dataService.addTransaction(Transaction(amount: -50.0, categoryId: cat0))
        try await dataService.addTransaction(Transaction(amount: 100.0, categoryId: cat10))

        // Manually load to verify computed properties
        try await dataService.loadData()

        // Wait for listener to fire
        try await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertEqual(dataService.totalBalance, 50.0)
    }

    // MARK: - Category Lookup

    func testCategoryLookup() {
        let category = dataService.categories[0]
        let found = dataService.category(for: category.id)
        XCTAssertEqual(found?.name, category.name)
    }

    func testCategoryLookupReturnsNilForUnknown() {
        let found = dataService.category(for: UUID())
        XCTAssertNil(found)
    }

    // MARK: - Grouped Transactions

    func testGroupedTransactions() async throws {
        let categoryId = ExpenseTrackerApp.Category.defaultCategories[0].id
        try await dataService.addTransaction(Transaction(amount: -10.0, categoryId: categoryId))

        try await dataService.loadData()
        try await Task.sleep(nanoseconds: 500_000_000)

        let grouped = dataService.groupedTransactions()
        // At least one group should exist
        XCTAssertFalse(grouped.isEmpty)
    }

    // MARK: - Batch Delete

    func testDeleteAllTransactions() async throws {
        let categoryId = ExpenseTrackerApp.Category.defaultCategories[0].id

        // Add a few transactions
        for i in 0..<3 {
            try await dataService.addTransaction(Transaction(amount: Double(-10 - i), categoryId: categoryId))
        }

        try await dataService.deleteAllTransactions()

        let db = Firestore.firestore()
        let snapshot = try await db.collection("users").document(testUID).collection("transactions").getDocuments()
        XCTAssertTrue(snapshot.documents.isEmpty)
    }
}
