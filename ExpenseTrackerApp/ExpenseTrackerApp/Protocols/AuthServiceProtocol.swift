//
//  AuthServiceProtocol.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 05/04/26.
//

import Foundation
import Combine

// MARK: - Auth State
enum AuthState {
    case loading
    case authenticated(UserProfile)
    case unauthenticated
}

// MARK: - Auth Service Protocol
@MainActor
protocol AuthServiceProtocol: ObservableObject {
    var authState: AuthState { get }

    func register(email: String, password: String, name: String, gender: String, phone: String, completion: @escaping (Result<UserProfile, Error>) -> Void)
    func login(email: String, password: String, completion: @escaping (Result<UserProfile, Error>) -> Void)
    func logout(completion: @escaping (Result<Void, Error>) -> Void)
    func addAuthStateListener(_ listener: @escaping (AuthState) -> Void)
    func removeAuthStateListener()
}
