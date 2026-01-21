import SwiftUI

struct PortfolioView: View {
    @ObservedObject var portfolioViewModel: PortfolioViewModel
    @State private var showingAddStock = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Portfolio")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button(action: { showingAddStock = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.borderless)
            }

            // Portfolio summary
            if !portfolioViewModel.portfolio.stocks.isEmpty {
                VStack(spacing: 8) {
                    HStack {
                        Text("Total Value:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(portfolioViewModel.totalPortfolioValue().toCurrency())
                            .fontWeight(.bold)
                    }

                    let totalGainLoss = portfolioViewModel.totalGainLoss()
                    HStack {
                        Text("Total Gain/Loss:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(totalGainLoss.toCurrency())
                            .fontWeight(.bold)
                            .foregroundColor(Color.forPriceChange(totalGainLoss))
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }

            // Stock list
            if portfolioViewModel.portfolio.stocks.isEmpty {
                Text("No stocks in portfolio")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                List {
                    ForEach(portfolioViewModel.portfolio.stocks) { stock in
                        PortfolioStockRow(stock: stock, portfolioViewModel: portfolioViewModel)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddStock) {
            AddStockView(portfolioViewModel: portfolioViewModel, isPresented: $showingAddStock)
        }
    }
}

struct PortfolioStockRow: View {
    let stock: Stock
    @ObservedObject var portfolioViewModel: PortfolioViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(stock.symbol)
                    .font(.headline)

                Spacer()

                if let currentValue = portfolioViewModel.currentValue(for: stock) {
                    Text(currentValue.toCurrency())
                        .fontWeight(.medium)
                }
            }

            if let shares = stock.shares, let purchasePrice = stock.purchasePrice {
                HStack {
                    Text("\(String(format: "%.2f", shares)) shares @ \(purchasePrice.toCurrency())")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if let gainLoss = portfolioViewModel.gainLoss(for: stock),
                       let gainLossPercent = portfolioViewModel.gainLossPercentage(for: stock) {
                        Text("\(gainLoss >= 0 ? "+" : "")\(gainLoss.toCurrency()) (\(gainLossPercent.toPercentage()))")
                            .font(.caption)
                            .foregroundColor(Color.forPriceChange(gainLoss))
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddStockView: View {
    @ObservedObject var portfolioViewModel: PortfolioViewModel
    @Binding var isPresented: Bool

    @State private var symbol: String = ""
    @State private var account: String = ""
    @State private var shares: String = ""
    @State private var purchasePrice: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Stock to Portfolio")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Symbol")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("AAPL", text: $symbol)
                        .textFieldStyle(.roundedBorder)
                        .textCase(.uppercase)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Account/Label")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Account 1", text: $account)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Shares (supports decimals)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("12.323", text: $shares)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Purchase Price")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("150.00", text: $purchasePrice)
                        .textFieldStyle(.roundedBorder)
                }
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)

                Button("Add") {
                    addStock()
                }
                .keyboardShortcut(.return)
                .disabled(symbol.isEmpty || account.isEmpty)
            }
        }
        .padding()
        .frame(width: 350)
    }

    private func addStock() {
        let shareCount = Double(shares)
        let price = Double(purchasePrice)

        portfolioViewModel.addStock(
            symbol: symbol,
            account: account.isEmpty ? "Default" : account,
            shares: shareCount,
            purchasePrice: price
        )

        isPresented = false
    }
}

struct EditStockView: View {
    let stock: Stock
    @ObservedObject var portfolioViewModel: PortfolioViewModel
    @Binding var isPresented: Bool

    @State private var symbol: String
    @State private var account: String
    @State private var shares: String
    @State private var purchasePrice: String

    init(stock: Stock, portfolioViewModel: PortfolioViewModel, isPresented: Binding<Bool>) {
        self.stock = stock
        self.portfolioViewModel = portfolioViewModel
        self._isPresented = isPresented

        // Pre-populate with existing values
        _symbol = State(initialValue: stock.symbol)
        _account = State(initialValue: stock.account)
        _shares = State(initialValue: stock.shares != nil ? String(stock.shares!) : "")
        _purchasePrice = State(initialValue: stock.purchasePrice != nil ? String(stock.purchasePrice!) : "")
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Stock Holding")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Symbol")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("AAPL", text: $symbol)
                        .textFieldStyle(.roundedBorder)
                        .textCase(.uppercase)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Account/Label")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Account 1", text: $account)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Shares (supports decimals)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("12.323", text: $shares)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Purchase Price")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("150.00", text: $purchasePrice)
                        .textFieldStyle(.roundedBorder)
                }
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)

                Button("Save") {
                    saveStock()
                }
                .keyboardShortcut(.return)
                .disabled(symbol.isEmpty || account.isEmpty)
            }
        }
        .padding()
        .frame(width: 350)
    }

    private func saveStock() {
        let shareCount = Double(shares)
        let price = Double(purchasePrice)

        // Create updated stock with same ID
        let updatedStock = Stock(
            id: stock.id,
            symbol: symbol.uppercased(),
            account: account.isEmpty ? "Default" : account,
            shares: shareCount,
            purchasePrice: price
        )

        portfolioViewModel.updateStock(updatedStock)
        isPresented = false
    }
}
