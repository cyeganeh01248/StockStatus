import Foundation

struct Stock: Codable, Identifiable, Equatable {
    let id: UUID
    let symbol: String
    var account: String  // Account/label to distinguish multiple entries
    var shares: Double?
    var purchasePrice: Double?

    init(id: UUID = UUID(), symbol: String, account: String = "Default", shares: Double? = nil, purchasePrice: Double? = nil) {
        self.id = id
        self.symbol = symbol
        self.account = account
        self.shares = shares
        self.purchasePrice = purchasePrice
    }

    // Calculate current value based on current price
    func currentValue(at price: Double) -> Double? {
        guard let shares = shares else { return nil }
        return shares * price
    }

    // Calculate gain/loss
    func gainLoss(at currentPrice: Double) -> Double? {
        guard let shares = shares, let purchasePrice = purchasePrice else { return nil }
        return (currentPrice - purchasePrice) * shares
    }

    // Calculate percentage gain/loss
    func gainLossPercentage(at currentPrice: Double) -> Double? {
        guard let purchasePrice = purchasePrice else { return nil }
        return ((currentPrice - purchasePrice) / purchasePrice) * 100
    }
}
