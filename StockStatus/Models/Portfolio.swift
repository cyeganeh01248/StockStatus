import Foundation

struct Portfolio: Codable {
    var stocks: [Stock]
    var lastUpdated: Date

    init(stocks: [Stock] = [], lastUpdated: Date = Date()) {
        self.stocks = stocks
        self.lastUpdated = lastUpdated
    }

    mutating func addStock(_ stock: Stock) {
        // Allow multiple entries for the same symbol
        stocks.append(stock)
        lastUpdated = Date()
    }

    mutating func removeStock(withId id: UUID) {
        stocks.removeAll { $0.id == id }
        lastUpdated = Date()
    }

    mutating func updateStock(_ stock: Stock) {
        if let index = stocks.firstIndex(where: { $0.id == stock.id }) {
            stocks[index] = stock
            lastUpdated = Date()
        }
    }

    func stocks(forSymbol symbol: String) -> [Stock] {
        stocks.filter { $0.symbol == symbol }
    }

    func stock(forSymbol symbol: String) -> Stock? {
        stocks.first { $0.symbol == symbol }
    }

    // Calculate total portfolio value
    func totalValue(prices: [String: Double]) -> Double {
        stocks.compactMap { stock in
            guard let price = prices[stock.symbol],
                  let value = stock.currentValue(at: price) else { return nil }
            return value
        }.reduce(0, +)
    }

    // Calculate total gain/loss
    func totalGainLoss(prices: [String: Double]) -> Double {
        stocks.compactMap { stock in
            guard let price = prices[stock.symbol],
                  let gainLoss = stock.gainLoss(at: price) else { return nil }
            return gainLoss
        }.reduce(0, +)
    }
}
