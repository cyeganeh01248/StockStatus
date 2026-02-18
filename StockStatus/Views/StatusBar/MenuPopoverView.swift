import SwiftUI

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

struct MenuPopoverView: View {
    @StateObject private var stockViewModel = StockViewModel()
    @StateObject private var portfolioViewModel = PortfolioViewModel()
    @State private var showingAddStock = false
    @State private var showingAddQuickSymbol = false
    @State private var expandedSections: Set<String> = []
    @State private var currentHeight: Double = 700

    var body: some View {
        ZStack {
            // Visual effect background for proper transparency
            VisualEffectBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with stock details
                    if let quote = stockViewModel.currentQuote {
                        StockDetailView(quote: quote, portfolioViewModel: portfolioViewModel)
                            .padding()
                    } else if stockViewModel.isLoading {
                        ProgressView("Loading...")
                            .padding()
                    } else if let error = stockViewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    }

                    Divider()

                    // Quick symbols with add/remove
                    QuickSymbolsEditView(
                        stockViewModel: stockViewModel,
                        showingAddSymbol: $showingAddQuickSymbol
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    Divider()

                    // Portfolio section with add/edit
                    PortfolioSectionView(
                        portfolioViewModel: portfolioViewModel,
                        showingAddStock: $showingAddStock
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    Divider()

                    // Update interval settings
                    UpdateIntervalView()
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                    Divider()

                    // Last updated timestamp
                    LastUpdatedView()
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                }
            }

            Divider()

            // Actions at bottom
            HStack(spacing: 12) {
                Button(action: {
                    stockViewModel.refresh()
                }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)

                Spacer()

                Button(action: quitApp) {
                    Label("Quit", systemImage: "xmark.circle")
                }
                .keyboardShortcut("q", modifiers: .command)
            }
            .buttonStyle(.borderless)
            .padding()
            }
        }
        .frame(width: 420, height: currentHeight)
        .onAppear {
            updateHeight()
        }
        .onReceive(NotificationCenter.default.publisher(for: .dropdownHeightChanged)) { _ in
            DispatchQueue.main.async {
                updateHeight()
            }
        }
        .onChange(of: UpdateManager.shared.currentSymbol) { _ in
            if UserDefaults.standard.dropdownHeightPreset == .dynamic {
                updateHeight()
            }
        }
        .onChange(of: portfolioViewModel.portfolio.stocks.count) { _ in
            if UserDefaults.standard.dropdownHeightPreset == .dynamic {
                updateHeight()
            }
        }
        .sheet(isPresented: $showingAddStock) {
            AddStockView(portfolioViewModel: portfolioViewModel, isPresented: $showingAddStock)
                .frame(minWidth: 350, minHeight: 250)
        }
        .sheet(isPresented: $showingAddQuickSymbol) {
            AddQuickSymbolView(isPresented: $showingAddQuickSymbol)
                .frame(minWidth: 350, minHeight: 200)
        }
    }

    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    private func updateHeight() {
        let screenHeight = NSScreen.main?.visibleFrame.height ?? 900
        // Count entries for the CURRENT symbol only
        let currentSymbol = UpdateManager.shared.currentSymbol
        let portfolioCount = portfolioViewModel.portfolio.stocks(forSymbol: currentSymbol).count
        let quickSymbolCount = DataManager.shared.getQuickSymbols().count

        currentHeight = UserDefaults.standard.dropdownHeightPreset.height(
            screenHeight: screenHeight,
            portfolioEntryCount: portfolioCount,
            quickSymbolCount: quickSymbolCount
        )
    }
}

// MARK: - Portfolio Section
struct PortfolioSectionView: View {
    @ObservedObject var portfolioViewModel: PortfolioViewModel
    @Binding var showingAddStock: Bool
    @State private var editingStock: Stock? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Your Portfolio")
                    .font(.headline)
                Spacer()
                Button(action: { showingAddStock = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.borderless)
                .help("Add stock to portfolio")
            }

            let stocks = portfolioViewModel.stocksForCurrentSymbol()
            if stocks.isEmpty {
                HStack {
                    Text("No holdings for this symbol")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Add Holdings") {
                        showingAddStock = true
                    }
                    .font(.caption)
                    .buttonStyle(.borderless)
                }
            } else {
                // Show all holdings for this symbol
                ForEach(stocks) { stock in
                    if let shares = stock.shares,
                       let purchasePrice = stock.purchasePrice,
                       let currentValue = portfolioViewModel.currentValue(for: stock),
                       let gainLoss = portfolioViewModel.gainLoss(for: stock),
                       let gainLossPercent = portfolioViewModel.gainLossPercentage(for: stock) {

                        VStack(alignment: .leading, spacing: 4) {
                            // Account/Label header
                            HStack {
                                Text(stock.account)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.accentColor)
                                Spacer()
                                Button(action: {
                                    editingStock = stock
                                }) {
                                    Image(systemName: "pencil")
                                        .font(.caption2)
                                        .foregroundColor(.accentColor)
                                }
                                .buttonStyle(.borderless)
                                .help("Edit this holding")

                                Button(action: {
                                    portfolioViewModel.removeStock(withId: stock.id)
                                }) {
                                    Image(systemName: "trash")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.borderless)
                                .help("Remove this holding")
                            }

                            HStack {
                                Text("Shares:")
                                Spacer()
                                Text(String(format: "%.3f", shares))
                                    .fontWeight(.medium)
                            }

                            HStack {
                                Text("Purchase Price:")
                                Spacer()
                                Text(purchasePrice.toCurrency())
                                    .fontWeight(.medium)
                            }

                            HStack {
                                Text("Current Value:")
                                Spacer()
                                Text(currentValue.toCurrency())
                                    .fontWeight(.medium)
                            }

                            HStack {
                                Text("Gain/Loss:")
                                Spacer()
                                Text("\(gainLoss.toCurrency()) (\(gainLossPercent.toPercentage()))")
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.forPriceChange(gainLoss))
                            }
                        }
                        .font(.caption)
                        .padding(8)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(6)
                    }
                }
            }
        }
        .sheet(item: $editingStock) { stock in
            EditStockView(stock: stock, portfolioViewModel: portfolioViewModel, isPresented: Binding(
                get: { editingStock != nil },
                set: { if !$0 { editingStock = nil } }
            ))
            .frame(minWidth: 350, minHeight: 250)
        }
    }
}

// MARK: - Quick Symbols Edit View
struct QuickSymbolsEditView: View {
    @ObservedObject var stockViewModel: StockViewModel
    @Binding var showingAddSymbol: Bool
    @State private var quickSymbols: [String] = []
    @State private var refreshTrigger = UUID()

    private let updateManager = UpdateManager.shared
    private let dataManager = DataManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Quick Symbols")
                    .font(.headline)
                Spacer()
                Button(action: { showingAddSymbol = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.borderless)
                .help("Add quick symbol")
            }

            VStack(spacing: 6) {
                ForEach(Array(quickSymbols.enumerated()), id: \.element) { index, symbol in
                    HStack(spacing: 6) {
                        // Symbol button with company name and price
                        Button(action: {
                            stockViewModel.switchSymbol(to: symbol)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(symbol)
                                        .font(.caption)
                                        .fontWeight(symbol == updateManager.currentSymbol ? .bold : .regular)

                                    if let quote = updateManager.quickQuotes[symbol],
                                       let companyName = quote.companyName {
                                        Text(companyName)
                                            .font(.system(size: 9))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }

                                Spacer()

                                if let quote = updateManager.quickQuotes[symbol] {
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(quote.price.toCurrency())
                                            .font(.caption)
                                            .fontWeight(.medium)

                                        let change = quote.priceChange
                                        let arrow = change >= 0 ? "▲" : "▼"
                                        Text("\(arrow) \(abs(change).toCurrency()) (\(abs(quote.priceChangePercentage).toPercentage()))")
                                            .font(.system(size: 9))
                                            .foregroundColor(Color.forPriceChange(change))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(symbol == updateManager.currentSymbol ? Color.accentColor.opacity(0.2) : Color.clear)
                            .cornerRadius(4)
                        }
                        .buttonStyle(.borderless)

                        // Move up button
                        Button(action: {
                            moveSymbol(from: index, direction: -1)
                        }) {
                            Image(systemName: "chevron.up")
                                .font(.caption2)
                                .foregroundColor(index > 0 ? .secondary : .clear)
                        }
                        .buttonStyle(.borderless)
                        .disabled(index == 0)
                        .help("Move up")

                        // Move down button
                        Button(action: {
                            moveSymbol(from: index, direction: 1)
                        }) {
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .foregroundColor(index < quickSymbols.count - 1 ? .secondary : .clear)
                        }
                        .buttonStyle(.borderless)
                        .disabled(index == quickSymbols.count - 1)
                        .help("Move down")

                        // Remove button
                        Button(action: {
                            removeSymbol(symbol)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.borderless)
                        .help("Remove \(symbol)")
                    }
                }
            }
        }
        .id(refreshTrigger)
        .onAppear {
            loadSymbols()
        }
        .onChange(of: showingAddSymbol) { isShowing in
            if !isShowing {
                // Refresh when sheet closes
                loadSymbols()
                refreshTrigger = UUID()
            }
        }
    }

    private func loadSymbols() {
        quickSymbols = dataManager.getQuickSymbols()
    }

    private func removeSymbol(_ symbol: String) {
        quickSymbols.removeAll { $0 == symbol }
        dataManager.setQuickSymbols(quickSymbols)
        updateManager.validateCurrentSymbol()
        updateManager.refreshNow()
    }

    private func moveSymbol(from index: Int, direction: Int) {
        let newIndex = index + direction
        guard newIndex >= 0 && newIndex < quickSymbols.count else { return }

        quickSymbols.swapAt(index, newIndex)
        dataManager.setQuickSymbols(quickSymbols)
        refreshTrigger = UUID()
    }
}

// MARK: - Update Interval View
struct UpdateIntervalView: View {
    @State private var updateInterval: Double = 60
    @State private var heightPreset: DropdownHeightPreset = .default
    private let dataManager = DataManager.shared
    private let updateManager = UpdateManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings")
                .font(.headline)

            HStack {
                Text("Update Interval:")
                    .font(.caption)
                Spacer()
                Picker("", selection: $updateInterval) {
                    Text("30 sec").tag(30.0)
                    Text("1 min").tag(60.0)
                    Text("2 min").tag(120.0)
                    Text("5 min").tag(300.0)
                }
                .pickerStyle(.menu)
                .frame(width: 100)
                .onChange(of: updateInterval) { newValue in
                    dataManager.setUpdateInterval(newValue)
                    updateManager.restartTimer()
                }
            }

            HStack {
                Text("Dropdown Height:")
                    .font(.caption)
                Spacer()
                Picker("", selection: $heightPreset) {
                    ForEach(DropdownHeightPreset.allCases) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 150)
                .onChange(of: heightPreset) { newValue in
                    UserDefaults.standard.dropdownHeightPreset = newValue
                    NotificationCenter.default.post(name: .dropdownHeightChanged, object: nil)
                }
            }
        }
        .onAppear {
            updateInterval = dataManager.getUpdateInterval()
            heightPreset = UserDefaults.standard.dropdownHeightPreset
        }
    }
}

extension Notification.Name {
    static let dropdownHeightChanged = Notification.Name("dropdownHeightChanged")
}

// MARK: - Add Quick Symbol Sheet
struct AddQuickSymbolView: View {
    @Binding var isPresented: Bool
    @State private var symbol: String = ""
    private let dataManager = DataManager.shared
    private let updateManager = UpdateManager.shared

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Quick Symbol")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 8) {
                Text("Stock Symbol")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("AAPL", text: $symbol)
                    .textFieldStyle(.roundedBorder)
                    .textCase(.uppercase)
                    .frame(width: 200)
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)

                Button("Add") {
                    addSymbol()
                }
                .keyboardShortcut(.return)
                .disabled(symbol.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }

    private func addSymbol() {
        let trimmed = symbol.uppercased().trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            dataManager.addQuickSymbol(trimmed)
            updateManager.validateCurrentSymbol()
            updateManager.refreshNow()
            isPresented = false
        }
    }
}

// MARK: - Last Updated View
struct LastUpdatedView: View {
    @ObservedObject private var updateManager = UpdateManager.shared
    @State private var currentTime = Date()

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack {
            Image(systemName: "clock")
                .font(.caption)
                .foregroundColor(.secondary)

            if let lastUpdate = updateManager.lastUpdateTime {
                Text("Updated \(timeAgoString(from: lastUpdate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Not yet updated")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .onReceive(timer) { time in
            currentTime = time
        }
    }

    private func timeAgoString(from date: Date) -> String {
        let seconds = Int(currentTime.timeIntervalSince(date))

        if seconds < 5 {
            return "just now"
        } else if seconds < 60 {
            return "\(seconds) seconds ago"
        } else if seconds < 120 {
            return "1 minute ago"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes) minutes ago"
        } else {
            let hours = seconds / 3600
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        }
    }
}
