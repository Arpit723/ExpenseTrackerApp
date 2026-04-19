//
//  AppError.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 19/04/26.
//

import Foundation

// MARK: - Sub-Error Types

enum AuthError: Equatable {
    case invalidCredentials
    case emailInUse
    case weakPassword
    case passwordMismatch
    case userNotFound
    case sessionExpired
}

enum NetworkError: Equatable {
    case noConnection
    case timeout
    case serverError(String)
}

enum DataError: Equatable {
    case saveFailed
    case loadFailed
    case deleteFailed
}

enum ValidationError: Equatable {
    case emptyField(String)
    case invalidEmail
    case invalidPassword
    case futureDate
    case invalidPhone
}

// MARK: - AppError

enum AppError: LocalizedError, Equatable {
    case auth(AuthError)
    case network(NetworkError)
    case data(DataError)
    case validation(ValidationError)

    var errorDescription: String? {
        switch self {
        // Auth
        case .auth(.invalidCredentials):
            return "Invalid email or password. Please try again."
        case .auth(.emailInUse):
            return "An account with this email already exists."
        case .auth(.weakPassword):
            return "Password is too weak. Use at least 6 characters with letters and numbers."
        case .auth(.passwordMismatch):
            return "Passwords do not match."
        case .auth(.userNotFound):
            return "No account found with this email address."
        case .auth(.sessionExpired):
            return "Your session has expired. Please log in again."

        // Network
        case .network(.noConnection):
            return "Unable to connect. Please check your internet connection."
        case .network(.timeout):
            return "The request timed out. Please try again."
        case .network(.serverError(let message)):
            return "Server error: \(message)"

        // Data
        case .data(.saveFailed):
            return "Failed to save. Changes will sync when you're back online."
        case .data(.loadFailed):
            return "Failed to load data. Pull to retry."
        case .data(.deleteFailed):
            return "Failed to delete. Will retry when you're back online."

        // Validation
        case .validation(.emptyField(let field)):
            return "Please enter \(field)."
        case .validation(.invalidEmail):
            return "Please enter a valid email address."
        case .validation(.invalidPassword):
            return "Password must be at least 6 characters with letters and numbers."
        case .validation(.futureDate):
            return "Date cannot be in the future."
        case .validation(.invalidPhone):
            return "Phone number must be at least 7 characters."
        }
    }

    // MARK: - Firebase Error Mapping

    static func from(firebaseError error: Error) -> AppError {
        let nsError = error as NSError

        // Network errors (NSURLDomain)
        if nsError.domain == NSURLErrorDomain {
            return .network(.noConnection)
        }

        // Firebase Auth errors
        if nsError.domain == "FIRAuthErrorDomain" {
            switch nsError.code {
            case 17008: // FIRAuthErrorCodeInvalidEmail
                return .auth(.invalidCredentials)
            case 17009: // FIRAuthErrorCodeWrongPassword
                return .auth(.invalidCredentials)
            case 17007: // FIRAuthErrorCodeEmailAlreadyInUse
                return .auth(.emailInUse)
            case 17026: // FIRAuthErrorCodeWeakPassword
                return .auth(.weakPassword)
            case 17011: // FIRAuthErrorCodeUserNotFound
                return .auth(.userNotFound)
            case 17020: // FIRAuthErrorCodeNetworkError
                return .network(.noConnection)
            case 17014: // FIRAuthErrorCodeInvalidCredential
                return .auth(.invalidCredentials)
            case 17010: // FIRAuthErrorCodeTooManyRequests
                return .network(.serverError("Too many attempts. Please try again later."))
            default:
                return .auth(.invalidCredentials)
            }
        }

        // Firestore errors
        if nsError.domain == "com.google.firebase.firestore" {
            return .data(.saveFailed)
        }

        return .network(.serverError(error.localizedDescription))
    }
}
