import Foundation
import SwiftUI
import AppKit

// MARK: - Double Extensions
extension Double {
    func toCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }

    func toPercentage() -> String {
        return String(format: "%.2f%%", self)
    }
}

// MARK: - Color Extensions
extension Color {
    static let positiveGreen = Color.green
    static let negativeRed = Color.red
    static let neutralGray = Color.gray

    static func forPriceChange(_ change: Double) -> Color {
        if change > 0 {
            return .positiveGreen
        } else if change < 0 {
            return .negativeRed
        } else {
            return .neutralGray
        }
    }
}

extension NSColor {
    static func forPriceChange(_ change: Double) -> NSColor {
        if change > 0 {
            return .systemGreen
        } else if change < 0 {
            return .systemRed
        } else {
            return .systemGray
        }
    }
}

// MARK: - Date Extensions
extension Date {
    func isMarketHours() -> Bool {
        let calendar = Calendar.current
        let easternTimeZone = TimeZone(identifier: "America/New_York")!
        let components = calendar.dateComponents(in: easternTimeZone, from: self)

        // Weekend check
        if let weekday = components.weekday, weekday == 1 || weekday == 7 {
            return false
        }

        guard let hour = components.hour, let minute = components.minute else {
            return false
        }

        let currentMinutes = hour * 60 + minute
        let openMinutes = AppConstants.marketOpenHour * 60 + AppConstants.marketOpenMinute
        let closeMinutes = AppConstants.marketCloseHour * 60 + AppConstants.marketCloseMinute

        return currentMinutes >= openMinutes && currentMinutes < closeMinutes
    }
}

// MARK: - UserDefaults Extensions
extension UserDefaults {
    var defaultSymbol: String {
        get { string(forKey: AppConstants.defaultSymbolKey) ?? AppConstants.defaultStockSymbol }
        set { set(newValue, forKey: AppConstants.defaultSymbolKey) }
    }

    var updateInterval: TimeInterval {
        get {
            let value = double(forKey: AppConstants.updateIntervalKey)
            return value > 0 ? value : AppConstants.defaultUpdateInterval
        }
        set { set(newValue, forKey: AppConstants.updateIntervalKey) }
    }

    var quickSymbols: [String] {
        get { stringArray(forKey: AppConstants.quickSymbolsKey) ?? AppConstants.defaultQuickSymbols }
        set { set(newValue, forKey: AppConstants.quickSymbolsKey) }
    }

    var statusBarDisplayMode: StatusBarDisplayMode {
        get {
            let rawValue = string(forKey: "statusBarDisplayMode") ?? "percentage"
            return StatusBarDisplayMode(rawValue: rawValue) ?? .percentage
        }
        set { set(newValue.rawValue, forKey: "statusBarDisplayMode") }
    }

    var dropdownHeightPreset: DropdownHeightPreset {
        get {
            let rawValue = string(forKey: "dropdownHeightPreset") ?? "default"
            return DropdownHeightPreset(rawValue: rawValue) ?? .default
        }
        set { set(newValue.rawValue, forKey: "dropdownHeightPreset") }
    }
}

// MARK: - Status Bar Display Mode
enum StatusBarDisplayMode: String {
    case percentage
    case dollar
}

// MARK: - Dropdown Height Preset
enum DropdownHeightPreset: String, CaseIterable, Identifiable {
    case compact = "compact"
    case `default` = "default"
    case tall = "tall"
    case extraTall = "extraTall"
    case dynamic = "dynamic"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .compact: return "Compact (550px)"
        case .default: return "Default (700px)"
        case .tall: return "Tall (850px)"
        case .extraTall: return "Extra Tall (1000px)"
        case .dynamic: return "Dynamic (Auto)"
        }
    }

    func height(screenHeight: Double = 900, portfolioEntryCount: Int = 0, quickSymbolCount: Int = 0) -> Double {
        let maxHeight = screenHeight - 100 // Leave 100px margin from top/bottom

        switch self {
        case .compact: return min(550, maxHeight)
        case .default: return min(700, maxHeight)
        case .tall: return min(850, maxHeight)
        case .extraTall: return min(1000, maxHeight)
        case .dynamic:
            // Calculate height based on content to hide settings section
            // Stock detail view: ~230px (includes chart, company name, etc.)
            // Divider: ~10px
            // Quick symbols header + content: ~50px + (~52px per symbol)
            // Divider: ~10px
            // Portfolio header + content: ~50px + (~115px per entry)
            // Divider: ~10px
            // Last updated: ~45px
            // Bottom padding: ~30px
            // Settings section should be hidden below the fold

            let baseHeight = 230.0 // Stock detail with chart
            let quickSymbolsHeight = 50.0 + (Double(quickSymbolCount) * 52.0) + 10.0 // +divider

            // Portfolio height: account for "No holdings" message when empty
            let portfolioHeight: Double
            if portfolioEntryCount == 0 {
                portfolioHeight = 50.0 + 35.0 + 10.0 // Header + "No holdings" message + divider
            } else {
                portfolioHeight = 50.0 + (Double(portfolioEntryCount) * 115.0) + 10.0 // Header + entries + divider
            }

            let lastUpdatedHeight = 45.0 + 10.0 // +divider
            let bottomPadding = 10.0 // Reduced to hide settings section

            let calculatedHeight = baseHeight + quickSymbolsHeight + portfolioHeight + lastUpdatedHeight + bottomPadding

            // Cap it at screen height
            let dynamicHeight = min(calculatedHeight, maxHeight)

            // Ensure minimum height of 400px
            return max(400, dynamicHeight)
        }
    }
}
