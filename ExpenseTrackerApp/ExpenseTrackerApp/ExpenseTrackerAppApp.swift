//
//  ExpenseTrackerAppApp.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

@main
struct ExpenseTrackerAppApp: App {
    // Initialize mock data service on app launch
    @StateObject private var dataService = MockDataService.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(dataService)
        }
    }
}
