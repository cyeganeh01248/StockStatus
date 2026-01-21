import Foundation

enum YahooFinanceError: Error {
    case invalidURL
    case invalidResponse
    case apiError(String)
    case networkError(Error)
    case decodingError(Error)
}

class YahooFinanceService {
    static let shared = YahooFinanceService()

    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = AppConstants.requestTimeout
        configuration.timeoutIntervalForResource = AppConstants.requestTimeout * 2
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Fetch Stock Quote

    func fetchQuote(symbol: String) async throws -> StockQuote {
        guard let url = URL(string: "\(AppConstants.yahooFinanceBaseURL)\(symbol)") else {
            throw YahooFinanceError.invalidURL
        }

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw YahooFinanceError.invalidResponse
            }

            let decoder = JSONDecoder()
            let yahooResponse = try decoder.decode(YahooFinanceResponse.self, from: data)

            // Check for API error
            if let error = yahooResponse.chart.error {
                throw YahooFinanceError.apiError(error.description)
            }

            // Extract quote from response
            guard let result = yahooResponse.chart.result?.first else {
                throw YahooFinanceError.invalidResponse
            }

            let meta = result.meta

            // Extract intraday data
            var intradayData: [IntradayPricePoint] = []
            if let timestamps = result.timestamp,
               let quoteData = result.indicators.quote.first,
               let closes = quoteData.close {

                for i in 0..<min(timestamps.count, closes.count) {
                    if let price = closes[i] {
                        let date = Date(timeIntervalSince1970: TimeInterval(timestamps[i]))
                        intradayData.append(IntradayPricePoint(timestamp: date, price: price))
                    }
                }
            }

            let quote = StockQuote(
                symbol: meta.symbol,
                companyName: meta.longName ?? meta.shortName,
                price: meta.regularMarketPrice,
                previousClose: meta.previousClose,
                dayHigh: meta.regularMarketDayHigh ?? meta.regularMarketPrice,
                dayLow: meta.regularMarketDayLow ?? meta.regularMarketPrice,
                volume: meta.regularMarketVolume ?? 0,
                timestamp: Date(),
                intradayData: intradayData
            )

            return quote

        } catch let error as DecodingError {
            throw YahooFinanceError.decodingError(error)
        } catch let error as YahooFinanceError {
            throw error
        } catch {
            throw YahooFinanceError.networkError(error)
        }
    }

    // MARK: - Fetch Multiple Quotes

    func fetchQuotes(symbols: [String]) async throws -> [String: StockQuote] {
        var quotes: [String: StockQuote] = [:]

        // Fetch quotes concurrently
        await withTaskGroup(of: (String, StockQuote?).self) { group in
            for symbol in symbols {
                group.addTask {
                    do {
                        let quote = try await self.fetchQuote(symbol: symbol)
                        return (symbol, quote)
                    } catch {
                        print("Error fetching quote for \(symbol): \(error)")
                        return (symbol, nil)
                    }
                }
            }

            for await (symbol, quote) in group {
                if let quote = quote {
                    quotes[symbol] = quote
                }
            }
        }

        return quotes
    }

    // MARK: - Validate Symbol

    func validateSymbol(_ symbol: String) async -> Bool {
        do {
            _ = try await fetchQuote(symbol: symbol)
            return true
        } catch {
            return false
        }
    }
}
