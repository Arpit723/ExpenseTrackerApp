//
//  QuickActionButton.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.appTextPrimary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Amount Button
struct QuickAmountButton: View {
    let amount: Double
    @Binding var selectedAmount: Double

    var body: some View {
        Button(action: {
            selectedAmount = amount
        }) {
            Text("$\(Int(amount))")
                .font(.system(size: 14, weight: selectedAmount == amount ? .semibold : .regular))
                .foregroundStyle(selectedAmount == amount ? .white : Color.appPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedAmount == amount ? Color.appPrimary : Color.appPrimary.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FAB (Floating Action Button)
struct FloatingAddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.appPrimary, Color.appSecondary]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.appPrimary.opacity(0.3), radius: 8, x: 0, y: 4)

                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            QuickActionButton(icon: "plus.circle.fill", title: "Add", color: .appPrimary, action: {})
            QuickActionButton(icon: "chart.bar.fill", title: "Reports", color: .appSecondary, action: {})
            QuickActionButton(icon: "target", title: "Goals", color: .appSuccess, action: {})
        }

        HStack(spacing: 8) {
            ForEach([5.0, 10.0, 20.0, 50.0, 100.0], id: \.self) { amount in
                QuickAmountButton(amount: amount, selectedAmount: .constant(20.0))
            }
        }

        FloatingAddButton(action: {})
    }
    .padding()
}
