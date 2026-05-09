//
//  FirebaseAuthService.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 19/04/26.
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation
import os

@MainActor
class FirebaseAuthService: ObservableObject, AuthServiceProtocol {
  @Published var authState: AuthState = .loading

  private var authStateListener: AuthStateDidChangeListenerHandle?
  private var stateCallback: ((AuthState) -> Void)?
  private let logger = Logger(subsystem: "com.brahmakumaris.expensetrackerapp", category: "Auth")

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
    logger.info("Setting up Firebase auth state listener")
    authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
      guard let self else { return }
      Task { @MainActor [weak self] in
        guard let self else { return }
        if let user = user {
          logger.info("Auth state changed: authenticated uid=\(user.uid)")
          let profile = await self.loadUserProfile(uid: user.uid, email: user.email)
          let state: AuthState = .authenticated(profile)
          self.authState = state
          self.stateCallback?(state)
        } else {
          logger.info("Auth state changed: unauthenticated")
          let state: AuthState = .unauthenticated
          self.authState = state
          self.stateCallback?(state)
        }
      }
    }
  }

  // MARK: - Load User Profile
  private func loadUserProfile(uid: String, email: String?) async -> UserProfile {
    do {
      let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
      if let profile = try? snapshot.data(as: UserProfile.self) {
        logger.info("loadUserProfile: loaded full profile for uid=\(uid)")
        return profile
      }
    } catch {
      logger.error("loadUserProfile: failed to load from Firestore — \(error.localizedDescription)")
    }
    return UserProfile(uid: uid, email: email, preferences: UserPreferences())
  }

  // MARK: - Register
  func register(email: String, password: String, name: String, birthDate: Date, phone: String)
    async throws -> UserProfile
  {
    logger.info("Register: creating Firebase Auth user for email=\(email)")
    do {
      let result = try await Auth.auth().createUser(withEmail: email, password: password)
      logger.info("Register: auth user created uid=\(result.user.uid)")

      let profile = UserProfile(
        uid: result.user.uid,
        email: result.user.email,
        fullName: name,
        birthDate: birthDate,
        phone: phone,
        preferences: UserPreferences()
      )

      // Save profile to Firestore — must succeed for registration to complete
      do {
        logger.info("Register: saving profile to Firestore for uid=\(result.user.uid)")
        try Firestore.firestore().collection("users").document(result.user.uid).setData(
          from: profile)
        logger.info("Register: profile saved successfully")
      } catch {
        logger.error("Register: Firestore save failed — \(error.localizedDescription)")
        try? await result.user.delete()
        logger.error(
          "Register: rollback delete failed — account may be orphaned for uid=\(result.user.uid)")
        logger.info("Register: rolled back auth account due to Firestore failure")
        throw AppError.from(firebaseError: error)
      }

      // Send email verification
      do {
        logger.info("Register: sending verification email")
        try await result.user.sendEmailVerification()
        logger.info("Register: verification email sent")
      } catch {
        logger.error("Register: verification email failed — \(error.localizedDescription)")
      }

      // Sign out immediately — user must verify email before logging in
      try Auth.auth().signOut()
      logger.info("Register: signed out after registration")

      return profile
    } catch let error as AppError {
      throw error
    } catch {
      logger.error("Register: Firebase Auth error — \(error.localizedDescription)")
      throw AppError.from(firebaseError: error)
    }
  }

  // MARK: - Login
  func login(email: String, password: String) async throws -> UserProfile {
    logger.info("Login: signing in email=\(email)")
    do {
      let result = try await Auth.auth().signIn(withEmail: email, password: password)
      logger.info("Login: success uid=\(result.user.uid)")

      // Check email verification
      if !result.user.isEmailVerified {
        logger.warning("Login: email not verified for uid=\(result.user.uid)")
        try Auth.auth().signOut()
        throw AppError.auth(.emailNotVerified)
      }

      let profile = await loadUserProfile(uid: result.user.uid, email: result.user.email)
      return profile
    } catch let error as AppError {
      throw error
    } catch {
      logger.error("Login: failed — \(error.localizedDescription)")
      throw AppError.from(firebaseError: error)
    }
  }

  // MARK: - Logout
  func logout() async throws {
    logger.info("Logout: signing out")
    do {
      try Auth.auth().signOut()
      logger.info("Logout: success")
    } catch {
      logger.error("Logout: failed — \(error.localizedDescription)")
      throw AppError.from(firebaseError: error)
    }
  }

  // MARK: - Delete Account
  func deleteAccount() async throws {
    guard let uid = Auth.auth().currentUser?.uid else {
      logger.warning("DeleteAccount: no current user")
      return
    }
    logger.info("DeleteAccount: deleting data for uid=\(uid)")
    do {
      let db = Firestore.firestore()
      let txCollection = db.collection("users").document(uid).collection("transactions")
      var hasMore = true
      while hasMore {
        let snapshot = try await txCollection.limit(to: 500).getDocuments()
        guard !snapshot.documents.isEmpty else {
          hasMore = false
          break
        }
        let batch = db.batch()
        for doc in snapshot.documents { batch.deleteDocument(doc.reference) }
        try await batch.commit()
        hasMore = snapshot.documents.count >= 500
      }
      try await db.collection("users").document(uid).delete()
      try await Auth.auth().currentUser?.delete()
      logger.info("DeleteAccount: success")
    } catch {
      logger.error("DeleteAccount: failed — \(error.localizedDescription)")
      throw AppError.from(firebaseError: error)
    }
  }

  // MARK: - Reset Password
  func resetPassword(email: String) async throws {
    logger.info("ResetPassword: sending reset email to \(email)")
    do {
      try await Auth.auth().sendPasswordReset(withEmail: email)
      logger.info("ResetPassword: email sent")
    } catch {
      logger.error("ResetPassword: failed — \(error.localizedDescription)")
      throw AppError.from(firebaseError: error)
    }
  }

  // MARK: - Update Profile
  func updateProfile(name: String, phone: String, birthDate: Date) async throws -> UserProfile {
    guard let currentUser = Auth.auth().currentUser else {
      logger.error("UpdateProfile: no current user")
      throw AppError.auth(.sessionExpired)
    }
    logger.info("UpdateProfile: updating profile for uid=\(currentUser.uid)")
    do {
      let snapshot = try await Firestore.firestore().collection("users").document(currentUser.uid)
        .getDocument()
      var existing = snapshot.exists ? (try? snapshot.data(as: UserProfile.self)) : nil

      let updated = UserProfile(
        id: existing?.id ?? UUID(),
        uid: currentUser.uid,
        email: currentUser.email,
        fullName: name,
        birthDate: birthDate,
        phone: phone,
        preferences: existing?.preferences ?? UserPreferences()
      )

      try Firestore.firestore().collection("users").document(currentUser.uid).setData(from: updated)
      logger.info("UpdateProfile: saved successfully")
      return updated
    } catch let error as AppError {
      throw error
    } catch {
      logger.error("UpdateProfile: failed — \(error.localizedDescription)")
      throw AppError.from(firebaseError: error)
    }
  }

  // MARK: - Send Email Verification
  func sendEmailVerification(email: String, password: String) async throws {
    logger.info("SendEmailVerification: signing in temporarily for email=\(email)")
    do {
      let result = try await Auth.auth().signIn(withEmail: email, password: password)
      try await result.user.sendEmailVerification()
      logger.info("SendEmailVerification: email sent, signing out")
      try Auth.auth().signOut()
    } catch let error as AppError {
      throw error
    } catch {
      logger.error("SendEmailVerification: failed — \(error.localizedDescription)")
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
