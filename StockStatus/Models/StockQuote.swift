import Foundation

struct StockQuote: Codable {
    let symbol: String
    let companyName: String?
    let price: Double
    let previousClose: Double
    let dayHigh: Double
    let dayLow: Double
    let volume: Int64
    let timestamp: Date
    let intradayData: [IntradayPricePoint]

    var priceChange: Double {
        price - previousClose
    }

    var priceChangePercentage: Double {
        (priceChange / previousClose) * 100
    }

    var isPositive: Bool {
        priceChange >= 0
    }
}

struct IntradayPricePoint: Codable, Identifiable {
    let id = UUID()
    let timestamp: Date
    let price: Double

    enum CodingKeys: String, CodingKey {
        case timestamp, price
    }
}

// MARK: - Yahoo Finance API Response Models
struct YahooFinanceResponse: Codable {
    let chart: ChartData
}

struct ChartData: Codable {
    let result: [ChartResult]?
    let error: YahooError?
}

struct YahooError: Codable {
    let code: String
    let description: String
}

struct ChartResult: Codable {
    let meta: Meta
    let timestamp: [Int]?
    let indicators: Indicators
}

struct Meta: Codable {
    let symbol: String
    let longName: String?
    let shortName: String?
    let regularMarketPrice: Double
    let previousClose: Double
    let regularMarketDayHigh: Double?
    let regularMarketDayLow: Double?
    let regularMarketVolume: Int64?
}

struct Indicators: Codable {
    let quote: [Quote]
}

struct Quote: Codable {
    let volume: [Int64?]?
    let close: [Double?]?
    let high: [Double?]?
    let low: [Double?]?
    let open: [Double?]?
}
