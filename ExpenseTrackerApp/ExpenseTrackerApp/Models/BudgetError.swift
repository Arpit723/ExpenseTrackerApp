//
//  BudgetError.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import Foundation

// MARK: - Budget Error
enum BudgetError: LocalizedError, Equatable {
    case invalidAmount
    case categoryAlreadyHasBudget
    case categoryNotFound
    case cannotDeleteOverallBudget
    case invalidDateRange
    case budgetNotFound
    case negativeAmount

    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Budget amount must be greater than zero."
        case .categoryAlreadyHasBudget:
            return "A budget already exists for this category. Please edit the existing budget instead."
        case .categoryNotFound:
            return "The selected category could not be found."
        case .cannotDeleteOverallBudget:
            return "The overall budget cannot be deleted. You can edit it instead."
        case .invalidDateRange:
            return "End date must be after start date."
        case .budgetNotFound:
            return "The budget could not be found."
        case .negativeAmount:
            return "Budget amount cannot be negative."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidAmount, .negativeAmount:
            return "Please enter a positive amount."
        case .categoryAlreadyHasBudget:
            return "Try editing the existing budget for this category."
        case .cannotDeleteOverallBudget:
            return "Set the overall budget amount to zero if you don't want to track it."
        default:
            return nil
        }
    }
}
