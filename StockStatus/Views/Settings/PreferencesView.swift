import SwiftUI

struct PreferencesView: View {
    @StateObject private var portfolioViewModel = PortfolioViewModel()
    @State private var defaultSymbol: String = ""
    @State private var updateInterval: Double = 60
    @State private var quickSymbols: [String] = []
    @State private var newQuickSymbol: String = ""
    @State private var selectedTab = 0

    private let dataManager = DataManager.shared
    private let updateManager = UpdateManager.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralPreferencesView(
                defaultSymbol: $defaultSymbol,
                updateInterval: $updateInterval,
                onSave: saveSettings
            )
            .tabItem {
                Label("General", systemImage: "gear")
            }
            .tag(0)

            QuickSymbolsPreferencesView(
                quickSymbols: $quickSymbols,
                newQuickSymbol: $newQuickSymbol,
                onSave: saveSettings
            )
            .tabItem {
                Label("Quick Symbols", systemImage: "star")
            }
            .tag(1)

            PortfolioPreferencesView(portfolioViewModel: portfolioViewModel)
                .tabItem {
                    Label("Portfolio", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            print("PreferencesView appeared")
            loadSettings()
        }
        .onDisappear {
            print("PreferencesView disappeared, saving settings")
            saveSettings()
        }
    }

    private func loadSettings() {
        defaultSymbol = dataManager.getDefaultSymbol()
        updateInterval = dataManager.getUpdateInterval()
        quickSymbols = dataManager.getQuickSymbols()
        print("Settings loaded: symbol=\(defaultSymbol), interval=\(updateInterval), quickSymbols=\(quickSymbols)")
    }

    private func saveSettings() {
        print("Saving settings: symbol=\(defaultSymbol), interval=\(updateInterval)")
        dataManager.setDefaultSymbol(defaultSymbol)
        dataManager.setUpdateInterval(updateInterval)
        dataManager.setQuickSymbols(quickSymbols)
        updateManager.restartTimer()
        print("Settings saved successfully")
    }
}

// MARK: - General Preferences
struct GeneralPreferencesView: View {
    @Binding var defaultSymbol: String
    @Binding var updateInterval: Double
    let onSave: () -> Void

    var body: some View {
        Form {
            Section(header: Text("General Settings").font(.headline)) {
                HStack {
                    Text("Default Symbol:")
                    TextField("AAPL", text: $defaultSymbol)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .textCase(.uppercase)
                }

                HStack {
                    Text("Update Interval:")
                    Picker("", selection: $updateInterval) {
                        Text("30 seconds").tag(30.0)
                        Text("1 minute").tag(60.0)
                        Text("2 minutes").tag(120.0)
                        Text("5 minutes").tag(300.0)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }

                Text("Note: More frequent updates may increase network usage.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Quick Symbols Preferences
struct QuickSymbolsPreferencesView: View {
    @Binding var quickSymbols: [String]
    @Binding var newQuickSymbol: String
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Symbols")
                .font(.headline)

            Text("Add your favorite stock symbols for quick access in the menu bar.")
                .font(.caption)
                .foregroundColor(.secondary)

            // Add new symbol
            HStack {
                TextField("Enter symbol (e.g., AAPL)", text: $newQuickSymbol)
                    .textFieldStyle(.roundedBorder)
                    .textCase(.uppercase)
                    .onSubmit {
                        addSymbol()
                    }

                Button(action: addSymbol) {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.borderless)
                .disabled(newQuickSymbol.isEmpty)
            }

            // List of quick symbols
            List {
                ForEach(quickSymbols, id: \.self) { symbol in
                    HStack {
                        Text(symbol)
                            .fontWeight(.medium)

                        Spacer()

                        Button(action: {
                            removeSymbol(symbol)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .onMove { indices, newOffset in
                    quickSymbols.move(fromOffsets: indices, toOffset: newOffset)
                }
            }

            Text("Drag to reorder symbols")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
    }

    private func addSymbol() {
        let symbol = newQuickSymbol.uppercased().trimmingCharacters(in: .whitespaces)
        if !symbol.isEmpty && !quickSymbols.contains(symbol) {
            quickSymbols.append(symbol)
            newQuickSymbol = ""
        }
    }

    private func removeSymbol(_ symbol: String) {
        quickSymbols.removeAll { $0 == symbol }
    }
}

// MARK: - Portfolio Preferences
struct PortfolioPreferencesView: View {
    @ObservedObject var portfolioViewModel: PortfolioViewModel
    @State private var showingAddStock = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Portfolio Holdings")
                    .font(.headline)

                Spacer()

                Button(action: { showingAddStock = true }) {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.borderless)
            }

            if portfolioViewModel.portfolio.stocks.isEmpty {
                VStack {
                    Text("No stocks in portfolio")
                        .foregroundColor(.secondary)

                    Button("Add Stock") {
                        showingAddStock = true
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                List {
                    ForEach(portfolioViewModel.portfolio.stocks) { stock in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(stock.symbol)
                                    .fontWeight(.bold)

                                if let shares = stock.shares, let price = stock.purchasePrice {
                                    Text("\(String(format: "%.2f", shares)) shares @ \(price.toCurrency())")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Button(action: {
                                portfolioViewModel.removeStock(withId: stock.id)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingAddStock) {
            AddStockView(portfolioViewModel: portfolioViewModel, isPresented: $showingAddStock)
        }
    }
}
