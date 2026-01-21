import SwiftUI

struct StockDetailView: View {
    let quote: StockQuote
    @ObservedObject var portfolioViewModel: PortfolioViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Symbol and company name
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(quote.symbol)
                        .font(.title)
                        .fontWeight(.bold)

                    if let companyName = quote.companyName {
                        Text(companyName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text(quote.price.toCurrency())
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            // Price change
            HStack {
                let change = quote.priceChange
                let percentChange = quote.priceChangePercentage
                let arrow = change >= 0 ? "▲" : "▼"

                Text("\(arrow) \(abs(change).toCurrency())")
                    .foregroundColor(Color.forPriceChange(change))

                Text("(\(abs(percentChange).toPercentage()))")
                    .foregroundColor(Color.forPriceChange(change))

                Spacer()
            }
            .font(.subheadline)

            Divider()

            // Intraday price chart
            if !quote.intradayData.isEmpty {
                StockChartView(intradayData: quote.intradayData, isPositive: quote.isPositive)
                    .padding(.vertical, 4)

                Divider()
            }

            // Market data
            VStack(spacing: 6) {
                HStack {
                    Text("Previous Close:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(quote.previousClose.toCurrency())
                }

                HStack {
                    Text("Day Range:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(quote.dayLow.toCurrency()) - \(quote.dayHigh.toCurrency())")
                }

                HStack {
                    Text("Volume:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatVolume(quote.volume))
                }
            }
            .font(.caption)
        }
    }

    private func formatVolume(_ volume: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2

        if volume >= 1_000_000_000 {
            return "\(formatter.string(from: NSNumber(value: Double(volume) / 1_000_000_000.0)) ?? "0")B"
        } else if volume >= 1_000_000 {
            return "\(formatter.string(from: NSNumber(value: Double(volume) / 1_000_000.0)) ?? "0")M"
        } else if volume >= 1_000 {
            return "\(formatter.string(from: NSNumber(value: Double(volume) / 1_000.0)) ?? "0")K"
        } else {
            return "\(volume)"
        }
    }
}
