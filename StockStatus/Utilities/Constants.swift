import Foundation

enum AppConstants {
    // User Defaults Keys
    static let defaultSymbolKey = "defaultSymbol"
    static let updateIntervalKey = "updateInterval"
    static let quickSymbolsKey = "quickSymbols"
    static let launchAtLoginKey = "launchAtLogin"

    // Default Values
    static let defaultStockSymbol = "AAPL"
    static let defaultUpdateInterval: TimeInterval = 60.0 // 1 minute
    static let defaultQuickSymbols = ["AAPL", "GOOGL", "MSFT", "TSLA", "AMZN"]

    // Market Hours (EST)
    static let marketOpenHour = 9
    static let marketOpenMinute = 30
    static let marketCloseHour = 16
    static let marketCloseMinute = 0

    // API
    static let yahooFinanceBaseURL = "https://query1.finance.yahoo.com/v8/finance/chart/"
    static let requestTimeout: TimeInterval = 10.0
}
