import SwiftUI
import Charts

struct StockChartView: View {
    let intradayData: [IntradayPricePoint]
    let isPositive: Bool

    private var minPrice: Double {
        intradayData.map { $0.price }.min() ?? 0
    }

    private var maxPrice: Double {
        intradayData.map { $0.price }.max() ?? 0
    }

    private var openingPrice: Double {
        intradayData.first?.price ?? 0
    }

    // Market hours: 9:30 AM - 4:00 PM EST
    private var marketOpen: Date {
        guard let firstPoint = intradayData.first else { return Date() }
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .timeZone], from: firstPoint.timestamp)
        components.hour = 9
        components.minute = 30
        return calendar.date(from: components) ?? firstPoint.timestamp
    }

    private var marketClose: Date {
        guard let firstPoint = intradayData.first else { return Date() }
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .timeZone], from: firstPoint.timestamp)
        components.hour = 16
        components.minute = 0
        return calendar.date(from: components) ?? firstPoint.timestamp
    }

    private func xAxisValues() -> [Date] {
        guard let firstPoint = intradayData.first else { return [] }
        let calendar = Calendar.current
        var values: [Date] = []

        let baseComponents = calendar.dateComponents([.year, .month, .day, .timeZone], from: firstPoint.timestamp)

        // Generate every 30 minutes from 9:30 AM to 4:00 PM
        let times: [(hour: Int, minute: Int)] = [
            (9, 30),   // 9:30 AM
            (10, 0),   // 10:00 AM
            (10, 30),  // 10:30 AM
            (11, 0),   // 11:00 AM
            (11, 30),  // 11:30 AM
            (12, 0),   // 12:00 PM
            (12, 30),  // 12:30 PM
            (13, 0),   // 1:00 PM
            (13, 30),  // 1:30 PM
            (14, 0),   // 2:00 PM
            (14, 30),  // 2:30 PM
            (15, 0),   // 3:00 PM
            (15, 30),  // 3:30 PM
            (16, 0)    // 4:00 PM
        ]

        for time in times {
            var components = baseComponents
            components.hour = time.hour
            components.minute = time.minute
            if let date = calendar.date(from: components) {
                values.append(date)
            }
        }

        return values
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !intradayData.isEmpty {
                Chart {
                    ForEach(intradayData) { point in
                        AreaMark(
                            x: .value("Time", point.timestamp),
                            yStart: .value("Min", minPrice),
                            yEnd: .value("Price", point.price)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    (isPositive ? Color.green : Color.red).opacity(0.3),
                                    (isPositive ? Color.green : Color.red).opacity(0.05)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Price", point.price)
                        )
                        .foregroundStyle(isPositive ? Color.green : Color.red)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                    }
                }
                .chartXScale(domain: marketOpen...marketClose)
                .chartYScale(domain: minPrice...maxPrice)
                .chartXAxis {
                    // Half-hour marks (lighter)
                    AxisMarks(values: .stride(by: .minute, count: 30)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.gray.opacity(0.42))
                    }
                    // Hour marks (bolder)
                    AxisMarks(values: .stride(by: .hour)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1.0))
                            .foregroundStyle(Color.gray.opacity(0.5))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing) { value in
                        AxisValueLabel {
                            if let price = value.as(Double.self) {
                                Text(price.toCurrency())
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartPlotStyle { plotArea in
                    plotArea
                        .background(.clear)
                }
                .frame(height: 120)
            } else {
                Text("No intraday data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}
