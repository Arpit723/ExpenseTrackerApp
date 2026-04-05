//
//  Color+Theme.swift
//  ExpenseTrackerApp
//
//  Created by Arpit Parekh on 28/03/26.
//

import SwiftUI

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let length = hexSanitized.count

        if length == 6 {
            self.init(
                red: Double((rgb & 0xFF0000) >> 16) / 255.0,
                green: Double((rgb & 0x00FF00) >> 8) / 255.0,
                blue: Double(rgb & 0x0000FF) / 255.0
            )
        } else if length == 8 {
            self.init(
                red: Double((rgb & 0xFF000000) >> 24) / 255.0,
                green: Double((rgb & 0x00FF0000) >> 16) / 255.0,
                blue: Double((rgb & 0x0000FF00) >> 8) / 255.0,
                opacity: Double(rgb & 0x000000FF) / 255.0
            )
        } else {
            return nil
        }
    }

    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return nil
        }

        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)

        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - App Theme Colors (SRS Section 6.2)
extension Color {
    static let appPrimary = Color(hex: "#007AFF") ?? .blue
    static let appSecondary = Color(hex: "#5856D6") ?? .purple
    static let appSuccess = Color(hex: "#34C759") ?? .green
    static let appWarning = Color(hex: "#FF9500") ?? .orange
    static let appDanger = Color(hex: "#FF3B30") ?? .red

    static let appBackground = Color(hex: "#F2F2F7") ?? Color(UIColor.systemGroupedBackground)
    static let appCardBackground = Color(UIColor.secondarySystemGroupedBackground)

    static let appTextPrimary = Color(UIColor.label)
    static let appTextSecondary = Color(UIColor.secondaryLabel)
    static let appTextTertiary = Color(UIColor.tertiaryLabel)

    static let appDivider = Color(UIColor.separator)
}
