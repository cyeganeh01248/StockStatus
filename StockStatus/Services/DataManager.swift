import Foundation

class DataManager {
    static let shared = DataManager()

    private init() {}

    private var portfolioURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let appDir = appSupport.appendingPathComponent("StockStatus")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("portfolio.json")
    }

    // MARK: - Portfolio Persistence

    func savePortfolio(_ portfolio: Portfolio) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(portfolio)
        try data.write(to: portfolioURL)
    }

    func loadPortfolio() -> Portfolio? {
        guard FileManager.default.fileExists(atPath: portfolioURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: portfolioURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(Portfolio.self, from: data)
        } catch {
            print("Error loading portfolio: \(error)")
            return nil
        }
    }

    // MARK: - User Preferences

    func getDefaultSymbol() -> String {
        return UserDefaults.standard.defaultSymbol
    }

    func setDefaultSymbol(_ symbol: String) {
        UserDefaults.standard.defaultSymbol = symbol.uppercased()
    }

    func getUpdateInterval() -> TimeInterval {
        return UserDefaults.standard.updateInterval
    }

    func setUpdateInterval(_ interval: TimeInterval) {
        UserDefaults.standard.updateInterval = interval
    }

    func getQuickSymbols() -> [String] {
        return UserDefaults.standard.quickSymbols
    }

    func setQuickSymbols(_ symbols: [String]) {
        UserDefaults.standard.quickSymbols = symbols.map { $0.uppercased() }
    }

    func addQuickSymbol(_ symbol: String) {
        var symbols = getQuickSymbols()
        let upperSymbol = symbol.uppercased()
        if !symbols.contains(upperSymbol) {
            symbols.append(upperSymbol)
            setQuickSymbols(symbols)
        }
    }

    func removeQuickSymbol(_ symbol: String) {
        var symbols = getQuickSymbols()
        symbols.removeAll { $0 == symbol.uppercased() }
        setQuickSymbols(symbols)
    }
}
