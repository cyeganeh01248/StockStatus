import Foundation
import Combine

class PortfolioViewModel: ObservableObject {
    @Published var portfolio: Portfolio
    @Published var currentPrices: [String: Double] = [:]

    private let dataManager = DataManager.shared
    private let updateManager = UpdateManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Load portfolio from disk or create new one
        if let savedPortfolio = dataManager.loadPortfolio() {
            self.portfolio = savedPortfolio
        } else {
            self.portfolio = Portfolio()
        }

        // Subscribe to quote updates
        updateManager.$currentQuote
            .compactMap { $0 }
            .sink { [weak self] quote in
                self?.currentPrices[quote.symbol] = quote.price
            }
            .store(in: &cancellables)

        updateManager.$quickQuotes
            .sink { [weak self] quotes in
                for (symbol, quote) in quotes {
                    self?.currentPrices[symbol] = quote.price
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Portfolio Management

    func addStock(symbol: String, account: String, shares: Double?, purchasePrice: Double?) {
        let stock = Stock(symbol: symbol.uppercased(), account: account, shares: shares, purchasePrice: purchasePrice)
        portfolio.addStock(stock)
        savePortfolio()
    }

    func removeStock(withId id: UUID) {
        portfolio.removeStock(withId: id)
        savePortfolio()
    }

    func updateStock(_ stock: Stock) {
        portfolio.updateStock(stock)
        savePortfolio()
    }

    private func savePortfolio() {
        do {
            try dataManager.savePortfolio(portfolio)
        } catch {
            print("Error saving portfolio: \(error)")
        }
    }

    // MARK: - Calculations

    func currentValue(for stock: Stock) -> Double? {
        guard let price = currentPrices[stock.symbol] else { return nil }
        return stock.currentValue(at: price)
    }

    func gainLoss(for stock: Stock) -> Double? {
        guard let price = currentPrices[stock.symbol] else { return nil }
        return stock.gainLoss(at: price)
    }

    func gainLossPercentage(for stock: Stock) -> Double? {
        guard let price = currentPrices[stock.symbol] else { return nil }
        return stock.gainLossPercentage(at: price)
    }

    func totalPortfolioValue() -> Double {
        return portfolio.totalValue(prices: currentPrices)
    }

    func totalGainLoss() -> Double {
        return portfolio.totalGainLoss(prices: currentPrices)
    }

    func stocksForCurrentSymbol() -> [Stock] {
        return portfolio.stocks(forSymbol: updateManager.currentSymbol)
    }

    func stockForCurrentSymbol() -> Stock? {
        return portfolio.stock(forSymbol: updateManager.currentSymbol)
    }
}
