//
//  FirebaseAuthService.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 19/04/26.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class FirebaseAuthService: ObservableObject, AuthServiceProtocol {
    @Published var authState: AuthState = .loading

    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var stateCallback: ((AuthState) -> Void)?

    // MARK: - Initialization
    init() {
        setupAuthListener()
    }

    deinit {
        if let handle = authStateListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Auth State Listener
    private func setupAuthListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            let state: AuthState
            if let user = user {
                let profile = UserProfile(
                    uid: user.uid,
                    email: user.email,
                    preferences: UserPreferences()
                )
                state = .authenticated(profile)
            } else {
                state = .unauthenticated
            }
            self.authState = state
            self.stateCallback?(state)
        }
    }

    // MARK: - Register
    func register(email: String, password: String, name: String, birthDate: Date, phone: String) async throws -> UserProfile {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let profile = UserProfile(
                uid: result.user.uid,
                email: result.user.email,
                fullName: name,
                birthDate: birthDate,
                phone: phone,
                preferences: UserPreferences()
            )

            // Save profile to Firestore
            try Firestore.firestore().collection("users").document(result.user.uid).setData(from: profile)

            return profile
        } catch {
            throw AppError.from(firebaseError: error)
        }
    }

    // MARK: - Login
    func login(email: String, password: String) async throws -> UserProfile {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let profile = UserProfile(
                uid: result.user.uid,
                email: result.user.email,
                preferences: UserPreferences()
            )
            return profile
        } catch {
            throw AppError.from(firebaseError: error)
        }
    }

    // MARK: - Logout
    func logout() async throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw AppError.from(firebaseError: error)
        }
    }

    // MARK: - Delete Account
    func deleteAccount() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            // Delete Firestore data before auth account
            let db = Firestore.firestore()
            let txCollection = db.collection("users").document(uid).collection("transactions")
            var hasMore = true
            while hasMore {
                let snapshot = try await txCollection.limit(to: 500).getDocuments()
                guard !snapshot.documents.isEmpty else { hasMore = false; break }
                let batch = db.batch()
                for doc in snapshot.documents { batch.deleteDocument(doc.reference) }
                try await batch.commit()
                hasMore = snapshot.documents.count >= 500
            }
            try await db.collection("users").document(uid).delete()
            try await Auth.auth().currentUser?.delete()
        } catch {
            throw AppError.from(firebaseError: error)
        }
    }

    // MARK: - Reset Password
    func resetPassword(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            throw AppError.from(firebaseError: error)
        }
    }

    // MARK: - State Listener Protocol
    func addAuthStateListener(_ listener: @escaping (AuthState) -> Void) {
        stateCallback = listener
        listener(authState)
    }

    func removeAuthStateListener() {
        stateCallback = nil
    }
}
