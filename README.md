# StockStatus - macOS Menu Bar Stock Tracker

A vibe coded native macOS status bar application that displays real-time stock prices and tracks your portfolio directly from your menu bar.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Real-time Stock Prices**: Display current stock prices in your menu bar with auto-updates
- **Status Bar Display Modes**: Right-click to toggle between percentage and dollar change display
- **Intraday Price Charts**: Visual charts showing stock price movement throughout the trading day
- **Portfolio Tracking**: Track multiple holdings per stock across different accounts
- **Fractional Shares**: Full support for decimal shares (up to 3 decimal places)
- **Multi-Account Support**: Track the same stock in multiple accounts/brokers separately
- **Quick Symbol Switching**: One-click switching between your favorite stocks
- **Customizable Dropdown**: Choose from preset heights or use dynamic sizing
- **Color-Coded Changes**: Green for gains, red for losses
- **Menu Bar Only**: Runs discreetly without cluttering your Dock

## Quick Start

### Build & Install
```bash
# Build, install, and launch
make install

# Or use the convenience command
(killall StockStatus || true) && make install && open /Applications/StockStatus.app
```

### Other Commands
```bash
make build      # Build the app
make clean      # Clean build artifacts
make run        # Run without installing
make uninstall  # Remove from /Applications
make zip        # Create distributable .zip
```

## Status Bar Features

**Display Modes** (right-click to toggle):
- Percentage: `AAPL $175.43 ▲ 2.31%`
- Dollar: `AAPL $175.43 ▲ $4.02`

**Color Coding**:
- 🟢 Green: Price increase
- 🔴 Red: Price decrease
- ⚪ Gray: No change

## Portfolio Features

### Multi-Account Support
Track the same stock across different accounts or purchase dates:

```
Symbol: AAPL
├─ Robinhood     → 10.000 shares at $123.45
├─ Fidelity      → 5.000 shares at $100.23
└─ 401k          → 25.500 shares at $150.00
```

Each entry shows:
- Account/label name
- Share count (with 3 decimal places)
- Purchase price
- Current value
- Individual gain/loss and percentage

### Adding Holdings

1. Click the menu bar item
2. Click `+` next to "Your Portfolio"
3. Fill in:
   - **Symbol**: Stock ticker (e.g., AAPL)
   - **Account/Label**: Account name (e.g., "Robinhood", "401k")
   - **Shares**: Number of shares (decimals supported: 10.523)
   - **Purchase Price**: Price per share when purchased
4. Click "Add"

### Managing Holdings

- **Edit**: Click the pencil icon on any holding
- **Delete**: Click the trash icon
- **Multiple Entries**: Add the same symbol multiple times with different accounts

## Dropdown Height Options

Configure dropdown size in Settings:

- **Compact** (550px): Minimal view
- **Default** (700px): Standard size
- **Tall** (850px): More content visible
- **Extra Tall** (1000px): Maximum content
- **Dynamic** (Auto): Automatically sizes to hide Settings section, adjusts based on portfolio entries

## Keyboard Shortcuts

- **⌘R** - Refresh prices immediately
- **⌘Q** - Quit application

## Requirements

- macOS 13.0 (Ventura) or later
- Active internet connection for fetching stock data

## Data Storage

- **Portfolio**: `~/Library/Application Support/StockStatus/portfolio.json`
- **Settings**: macOS UserDefaults
- **No Cloud Sync**: All data stored locally

## Development

### Project Structure
```
StockStatus/
├── Models/              # Data models (Stock, Portfolio, StockQuote)
├── ViewModels/          # Business logic layer
├── Views/               # SwiftUI and AppKit views
│   ├── StatusBar/       # Menu bar controller and popover
│   ├── Portfolio/       # Portfolio views
│   └── Settings/        # Preferences window
├── Services/            # API and data services
│   ├── YahooFinanceService.swift
│   ├── DataManager.swift
│   └── UpdateManager.swift
└── Utilities/           # Extensions and constants
```

### Architecture

- **MVVM Pattern**: Clean separation between views and business logic
- **Combine Framework**: Reactive updates for real-time price changes
- **SwiftUI + AppKit**: SwiftUI views hosted in AppKit menu bar
- **Async/Await**: Modern Swift concurrency for API calls

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed architecture documentation.

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Troubleshooting

### App shows "Loading..." indefinitely
- Check your internet connection
- Verify the stock symbol exists (try AAPL to test)
- Check if Yahoo Finance is accessible

### Prices aren't updating
- Refresh manually with ⌘R
- Check the update interval in Settings
- Note: Outside market hours (9:30 AM - 4:00 PM EST), prices update with delay

### Symbol not found
- Ensure you're using the correct ticker symbol
- Try searching on [Yahoo Finance](https://finance.yahoo.com) first
- Use the symbol exactly as it appears on Yahoo Finance

### Build Errors
```bash
# Clean and rebuild
make clean
make build

# Or with Swift directly
swift package clean
swift build -c release
```

## Known Limitations

- **Market Hours**: Prices update only during trading hours (9:30 AM - 4:00 PM EST)
- **Delayed Data**: Yahoo Finance provides ~15-minute delayed quotes
- **No Pre/Post Market**: Only regular trading hours supported
- **USD Only**: Prices displayed in US dollars

## Data Source

Stock data is fetched from Yahoo Finance API:
- Real-time price data (~15-minute delay)
- No API key required
- Free to use

## Privacy

- Only makes network requests to Yahoo Finance for stock prices
- No personal data collected or transmitted
- Portfolio information stays on your Mac
- No analytics or tracking

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

- Stock data provided by [Yahoo Finance](https://finance.yahoo.com)
- Built with Swift, SwiftUI, and AppKit
- Designed for macOS 13.0+

---

**Disclaimer**: This application is for informational purposes only and should not be considered financial advice. Always verify stock prices and portfolio calculations independently before making investment decisions.
