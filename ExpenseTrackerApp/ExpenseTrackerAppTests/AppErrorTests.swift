//
//  AppErrorTests.swift
//  ExpenseTrackerAppTests
//
//  Created by Arpit Parekh on 19/04/26.
//

import XCTest
@testable import ExpenseTrackerApp

final class AppErrorTests: XCTestCase {

    // MARK: - Auth Errors

    func testAuthError_invalidCredentials() {
        let error = AppError.auth(.invalidCredentials)
        XCTAssertEqual(error.errorDescription, "Invalid email or password. Please try again.")
    }

    func testAuthError_emailInUse() {
        let error = AppError.auth(.emailInUse)
        XCTAssertEqual(error.errorDescription, "An account with this email already exists.")
    }

    func testAuthError_weakPassword() {
        let error = AppError.auth(.weakPassword)
        XCTAssertEqual(error.errorDescription, "Password is too weak. Use at least 6 characters with letters and numbers.")
    }

    func testAuthError_passwordMismatch() {
        let error = AppError.auth(.passwordMismatch)
        XCTAssertEqual(error.errorDescription, "Passwords do not match.")
    }

    func testAuthError_userNotFound() {
        let error = AppError.auth(.userNotFound)
        XCTAssertEqual(error.errorDescription, "No account found with this email address.")
    }

    func testAuthError_sessionExpired() {
        let error = AppError.auth(.sessionExpired)
        XCTAssertEqual(error.errorDescription, "Your session has expired. Please log in again.")
    }

    func testAuthErrors_haveUserFriendlyMessages() {
        let errors: [AuthError] = [.invalidCredentials, .emailInUse, .weakPassword, .passwordMismatch, .userNotFound, .sessionExpired]
        for authError in errors {
            let message = AppError.auth(authError).errorDescription
            XCTAssertNotNil(message, "AuthError.\(authError) should have a message")
            XCTAssertFalse(message!.isEmpty, "AuthError.\(authError) message should not be empty")
        }
    }

    // MARK: - Network Errors

    func testNetworkError_noConnection() {
        let error = AppError.network(.noConnection)
        XCTAssertEqual(error.errorDescription, "Unable to connect. Please check your internet connection.")
    }

    func testNetworkError_timeout() {
        let error = AppError.network(.timeout)
        XCTAssertEqual(error.errorDescription, "The request timed out. Please try again.")
    }

    func testNetworkError_serverError() {
        let error = AppError.network(.serverError("Internal error"))
        XCTAssertEqual(error.errorDescription, "Server error: Internal error")
    }

    func testNetworkErrors_haveUserFriendlyMessages() {
        let errors: [NetworkError] = [.noConnection, .timeout, .serverError("test")]
        for netError in errors {
            let message = AppError.network(netError).errorDescription
            XCTAssertNotNil(message, "NetworkError should have a message")
            XCTAssertFalse(message!.isEmpty, "NetworkError message should not be empty")
        }
    }

    // MARK: - Data Errors

    func testDataError_saveFailed() {
        let error = AppError.data(.saveFailed)
        XCTAssertEqual(error.errorDescription, "Failed to save. Changes will sync when you're back online.")
    }

    func testDataError_loadFailed() {
        let error = AppError.data(.loadFailed)
        XCTAssertEqual(error.errorDescription, "Failed to load data. Pull to retry.")
    }

    func testDataError_deleteFailed() {
        let error = AppError.data(.deleteFailed)
        XCTAssertEqual(error.errorDescription, "Failed to delete. Will retry when you're back online.")
    }

    func testDataErrors_haveUserFriendlyMessages() {
        let errors: [DataError] = [.saveFailed, .loadFailed, .deleteFailed]
        for dataError in errors {
            let message = AppError.data(dataError).errorDescription
            XCTAssertNotNil(message, "DataError should have a message")
            XCTAssertFalse(message!.isEmpty, "DataError message should not be empty")
        }
    }

    // MARK: - Validation Errors

    func testValidationError_emptyField() {
        let error = AppError.validation(.emptyField("Email"))
        XCTAssertEqual(error.errorDescription, "Please enter Email.")
    }

    func testValidationError_invalidEmail() {
        let error = AppError.validation(.invalidEmail)
        XCTAssertEqual(error.errorDescription, "Please enter a valid email address.")
    }

    func testValidationError_invalidPassword() {
        let error = AppError.validation(.invalidPassword)
        XCTAssertEqual(error.errorDescription, "Password must be at least 6 characters with letters and numbers.")
    }

    func testValidationError_futureDate() {
        let error = AppError.validation(.futureDate)
        XCTAssertEqual(error.errorDescription, "Date cannot be in the future.")
    }

    func testValidationError_invalidPhone() {
        let error = AppError.validation(.invalidPhone)
        XCTAssertEqual(error.errorDescription, "Phone number must be at least 7 characters.")
    }

    func testValidationErrors_haveUserFriendlyMessages() {
        let errors: [ValidationError] = [.emptyField("Test"), .invalidEmail, .invalidPassword, .futureDate, .invalidPhone]
        for valError in errors {
            let message = AppError.validation(valError).errorDescription
            XCTAssertNotNil(message, "ValidationError should have a message")
            XCTAssertFalse(message!.isEmpty, "ValidationError message should not be empty")
        }
    }

    // MARK: - Firebase Error Mapping

    func testFirebaseErrorMapping_invalidEmail() {
        let firebaseError = NSError(domain: "FIRAuthErrorDomain", code: 17008, userInfo: [NSLocalizedDescriptionKey: "The email address is badly formatted."])
        let appError = AppError.from(firebaseError: firebaseError)
        XCTAssertEqual(appError, AppError.auth(.invalidCredentials))
    }

    func testFirebaseErrorMapping_wrongPassword() {
        let firebaseError = NSError(domain: "FIRAuthErrorDomain", code: 17009, userInfo: [NSLocalizedDescriptionKey: "The password is invalid."])
        let appError = AppError.from(firebaseError: firebaseError)
        XCTAssertEqual(appError, AppError.auth(.invalidCredentials))
    }

    func testFirebaseErrorMapping_emailInUse() {
        let firebaseError = NSError(domain: "FIRAuthErrorDomain", code: 17007, userInfo: [NSLocalizedDescriptionKey: "The email address is already in use."])
        let appError = AppError.from(firebaseError: firebaseError)
        XCTAssertEqual(appError, AppError.auth(.emailInUse))
    }

    func testFirebaseErrorMapping_weakPassword() {
        let firebaseError = NSError(domain: "FIRAuthErrorDomain", code: 17026, userInfo: [NSLocalizedDescriptionKey: "The password must be 6 characters long."])
        let appError = AppError.from(firebaseError: firebaseError)
        XCTAssertEqual(appError, AppError.auth(.weakPassword))
    }

    func testFirebaseErrorMapping_userNotFound() {
        let firebaseError = NSError(domain: "FIRAuthErrorDomain", code: 17011, userInfo: [NSLocalizedDescriptionKey: "There is no user record."])
        let appError = AppError.from(firebaseError: firebaseError)
        XCTAssertEqual(appError, AppError.auth(.userNotFound))
    }

    func testFirebaseErrorMapping_networkError() {
        let firebaseError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: [NSLocalizedDescriptionKey: "No internet connection"])
        let appError = AppError.from(firebaseError: firebaseError)
        XCTAssertEqual(appError, AppError.network(.noConnection))
    }

    func testFirebaseErrorMapping_unknownError() {
        let unknownError = NSError(domain: "SomeDomain", code: 999, userInfo: [NSLocalizedDescriptionKey: "Something went wrong"])
        let appError = AppError.from(firebaseError: unknownError)
        // Unknown errors should map to a generic message
        XCTAssertNotNil(appError.errorDescription)
        XCTAssertFalse(appError.errorDescription!.isEmpty)
    }

    // MARK: - Equatable Conformance

    func testAppErrorEquatable_sameErrors() {
        XCTAssertEqual(AppError.auth(.invalidCredentials), AppError.auth(.invalidCredentials))
    }

    func testAppErrorEquatable_differentErrors() {
        XCTAssertNotEqual(AppError.auth(.invalidCredentials), AppError.auth(.emailInUse))
        XCTAssertNotEqual(AppError.auth(.invalidCredentials), AppError.network(.noConnection))
    }
}
