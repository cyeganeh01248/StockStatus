import Cocoa
import SwiftUI
import Combine

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private let updateManager = UpdateManager.shared
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        setupStatusItem()
        setupPopover()
        subscribeToUpdates()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "Loading..."
            button.action = #selector(togglePopover)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        let screenHeight = NSScreen.main?.visibleFrame.height ?? 900
        let currentSymbol = updateManager.currentSymbol
        let portfolioCount = DataManager.shared.loadPortfolio()?.stocks(forSymbol: currentSymbol).count ?? 0
        let quickSymbolCount = DataManager.shared.getQuickSymbols().count
        let height = UserDefaults.standard.dropdownHeightPreset.height(
            screenHeight: screenHeight,
            portfolioEntryCount: portfolioCount,
            quickSymbolCount: quickSymbolCount
        )
        popover?.contentSize = NSSize(width: 420, height: height)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: MenuPopoverView())

        // Listen for height changes
        NotificationCenter.default.addObserver(forName: .dropdownHeightChanged, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            let screenHeight = NSScreen.main?.visibleFrame.height ?? 900
            let currentSymbol = self.updateManager.currentSymbol
            let portfolioCount = DataManager.shared.loadPortfolio()?.stocks(forSymbol: currentSymbol).count ?? 0
            let quickSymbolCount = DataManager.shared.getQuickSymbols().count
            let newHeight = UserDefaults.standard.dropdownHeightPreset.height(
                screenHeight: screenHeight,
                portfolioEntryCount: portfolioCount,
                quickSymbolCount: quickSymbolCount
            )
            self.popover?.contentSize = NSSize(width: 420, height: newHeight)
        }
    }

    private func subscribeToUpdates() {
        // Update status bar when quote changes
        updateManager.$currentQuote
            .receive(on: DispatchQueue.main)
            .sink { [weak self] quote in
                self?.updateStatusBarText(with: quote)
            }
            .store(in: &cancellables)
    }

    private func updateStatusBarText(with quote: StockQuote?) {
        guard let button = statusItem?.button else { return }

        if let quote = quote {
            let priceChange = quote.priceChange
            let percentChange = quote.priceChangePercentage
            let arrow = priceChange >= 0 ? "▲" : "▼"
            let color = NSColor.forPriceChange(priceChange)

            // Get display mode preference
            let displayMode = UserDefaults.standard.statusBarDisplayMode

            // Create attributed string with color
            let text: String
            switch displayMode {
            case .percentage:
                text = String(format: "%@ $%.2f %@ %.2f%%",
                            quote.symbol,
                            quote.price,
                            arrow,
                            abs(percentChange))
            case .dollar:
                text = String(format: "%@ $%.2f %@ $%.2f",
                            quote.symbol,
                            quote.price,
                            arrow,
                            abs(priceChange))
            }

            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: color,
                .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
            ]

            button.attributedTitle = NSAttributedString(string: text, attributes: attributes)
        } else {
            button.title = "Loading..."
        }
    }

    @objc private func togglePopover() {
        guard let event = NSApp.currentEvent else { return }

        // Right-click toggles display mode
        if event.type == .rightMouseUp {
            toggleDisplayMode()
            return
        }

        // Left-click toggles popover
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(nil)
            } else {
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    private func toggleDisplayMode() {
        let currentMode = UserDefaults.standard.statusBarDisplayMode
        let newMode: StatusBarDisplayMode = currentMode == .percentage ? .dollar : .percentage
        UserDefaults.standard.statusBarDisplayMode = newMode

        // Refresh the display
        updateStatusBarText(with: updateManager.currentQuote)
    }

    func showPopover() {
        if let button = statusItem?.button {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    func hidePopover() {
        popover?.performClose(nil)
    }
}
