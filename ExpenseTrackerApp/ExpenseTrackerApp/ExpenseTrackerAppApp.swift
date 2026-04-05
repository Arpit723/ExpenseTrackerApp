//
//  ExpenseTrackerAppApp.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

@main
struct ExpenseTrackerAppApp: App {
    @StateObject private var dataService = DataService.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(dataService)
        }
    }
}
