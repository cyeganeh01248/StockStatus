import Foundation
import Combine

class UpdateManager: ObservableObject {
    static let shared = UpdateManager()

    @Published var currentQuote: StockQuote?
    @Published var currentSymbol: String
    @Published var quickQuotes: [String: StockQuote] = [:]
    @Published var isUpdating: Bool = false
    @Published var lastUpdateTime: Date?
    @Published var errorMessage: String?

    private var updateTimer: Timer?
    private let yahooFinance = YahooFinanceService.shared
    private let dataManager = DataManager.shared

    private init() {
        self.currentSymbol = DataManager.shared.getDefaultSymbol()
    }

    // MARK: - Timer Management

    func startUpdating() {
        // Initial fetch
        Task {
            await fetchCurrentStock()
            await fetchQuickSymbols()
        }

        // Schedule timer
        let interval = dataManager.getUpdateInterval()
        updateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task {
                await self?.fetchCurrentStock()
                await self?.fetchQuickSymbols()
            }
        }

        // Ensure timer works even when menu is open
        if let timer = updateTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    func stopUpdating() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    func restartTimer() {
        stopUpdating()
        startUpdating()
    }

    // MARK: - Fetch Stock Data

    @MainActor
    func fetchCurrentStock() async {
        isUpdating = true
        errorMessage = nil

        do {
            let quote = try await yahooFinance.fetchQuote(symbol: currentSymbol)
            currentQuote = quote
            lastUpdateTime = Date()
        } catch {
            errorMessage = "Failed to fetch \(currentSymbol): \(error.localizedDescription)"
            print("Error fetching current stock: \(error)")
        }

        isUpdating = false
    }

    @MainActor
    func fetchQuickSymbols() async {
        let symbols = dataManager.getQuickSymbols()

        do {
            let quotes = try await yahooFinance.fetchQuotes(symbols: symbols)
            quickQuotes = quotes
        } catch {
            print("Error fetching quick symbols: \(error)")
        }
    }

    // MARK: - Symbol Management

    func switchSymbol(to symbol: String) {
        currentSymbol = symbol.uppercased()
        dataManager.setDefaultSymbol(currentSymbol)

        Task {
            await fetchCurrentStock()
        }
    }

    func refreshNow() {
        Task {
            await fetchCurrentStock()
            await fetchQuickSymbols()
        }
    }

    // MARK: - Market Hours Check

    func isMarketOpen() -> Bool {
        return Date().isMarketHours()
    }
}
