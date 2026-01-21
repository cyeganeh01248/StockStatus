# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

StockStatus is a native macOS status bar application that displays real-time stock prices and portfolio tracking. Built with Swift, SwiftUI, and AppKit, it uses Yahoo Finance API for stock data.

**Key Info:**
- **Platform:** macOS 13.0+ (Ventura)
- **Bundle ID:** com.stockstatus.app
- **Language:** Swift 5.9
- **Frameworks:** SwiftUI, AppKit, Combine
- **Build System:** Swift Package Manager + Makefile

## Build Commands

### Standard Build
```bash
# Clean and build
make build

# Build only (SPM)
swift build -c release

# Run from build directory
.build/release/StockStatus

# Run from app bundle
open StockStatus.app
```

### Installation
```bash
# Install to /Applications
make install

# Uninstall
make uninstall

# Run locally
make run
```

### Xcode Development
```bash
open StockStatus.xcodeproj
# Then ⌘R to build and run
```

## Architecture

### Hybrid AppKit/SwiftUI Pattern

StockStatus uses a hybrid approach because NSStatusItem (menu bar) requires AppKit, while all UI views are built with SwiftUI:

**AppKit Layer:**
- `AppDelegate`: Main app coordinator, initializes StatusBarController and UpdateManager
- `StatusBarController`: Manages NSStatusItem, button, and NSPopover
- `PreferencesWindowController`: Hosts SwiftUI preferences in NSWindow

**SwiftUI Layer:**
- All views (MenuPopoverView, PortfolioView, StockDetailView, PreferencesView)
- ViewModels use Combine @Published properties for reactive updates

### MVVM + Services Architecture

```
Models (Data)
  ├── Stock.swift (portfolio holding)
  ├── Portfolio.swift (collection of stocks)
  └── StockQuote.swift (API response)

ViewModels (Business Logic)
  ├── StockViewModel (current quote display)
  └── PortfolioViewModel (holdings management)

Views (UI - SwiftUI)
  ├── StatusBar/
  │   ├── StatusBarController (AppKit)
  │   └── MenuPopoverView (SwiftUI)
  ├── Portfolio/
  │   ├── PortfolioView
  │   └── StockDetailView
  └── Settings/
      ├── PreferencesWindowController (AppKit)
      └── PreferencesView (SwiftUI)

Services (Data & Network)
  ├── YahooFinanceService (API calls)
  ├── DataManager (persistence)
  └── UpdateManager (timer & state)
```

### Critical Implementation Details

**UpdateManager Singleton:**
- Central state manager using Combine's `ObservableObject`
- Timer runs on `.common` RunLoop mode to continue during menu interaction
- All network calls use Swift async/await, results published on @MainActor
- Manages `currentSymbol`, `currentQuote`, `quickQuotes`, `isUpdating`, `lastUpdateTime`

**Data Flow:**
1. Timer fires → UpdateManager.fetchCurrentStock()
2. YahooFinanceService makes async URLSession call
3. Response decoded to StockQuote
4. UpdateManager publishes to @Published properties
5. StatusBarController Combine subscription updates menu bar button
6. SwiftUI views automatically re-render via @ObservedObject binding

**Persistence:**
- Portfolio: JSON file at `~/Library/Application Support/StockStatus/portfolio.json`
- Settings: UserDefaults via extensions in `Utilities/Extensions.swift`
- Portfolio uses ISO8601 date encoding with pretty printing

**Yahoo Finance API:**
- Base URL: `https://query1.finance.yahoo.com/v8/finance/chart/`
- No API key required
- Returns JSON with nested structure: `chart.result[0].meta`
- Request timeout: 10 seconds (configured in AppConstants)
- Concurrent fetching for multiple symbols via TaskGroup

## Code Patterns & Conventions

### When Adding Network Features
- Use `async/await` with YahooFinanceService
- Publish results via UpdateManager's @Published properties
- Always catch and handle YahooFinanceError cases
- Update UI on @MainActor after async operations

### When Adding UI Components
- Use SwiftUI for all new views
- Connect to ViewModels via @StateObject or @ObservedObject
- For menu bar updates, subscribe to UpdateManager in StatusBarController
- Preferences use @AppStorage for automatic UserDefaults binding

### When Modifying Data Models
- Update Codable conformance for JSON persistence
- If changing Portfolio structure, handle migration in DataManager.loadPortfolio()
- Stock symbols always uppercased via DataManager

### Threading Model
- Network calls: Background threads via URLSession/async-await
- UI updates: @MainActor (automatic in SwiftUI, explicit in UpdateManager)
- Timer: RunLoop.current with .common mode
- Concurrent stock fetches: withTaskGroup

## Key Files

### Entry Points
- `StockStatusApp.swift:1` - @main entry point
- `AppDelegate.swift:25` - applicationDidFinishLaunching initializes app

### Core Services
- `Services/YahooFinanceService.swift:25` - fetchQuote() API call
- `Services/UpdateManager.swift:24` - startUpdating() timer setup
- `Services/DataManager.swift:17` - savePortfolio() persistence

### UI Controllers
- `Views/StatusBar/StatusBarController.swift` - Menu bar integration
- `Views/Settings/PreferencesWindowController.swift` - Settings window

### Constants & Extensions
- `Utilities/Constants.swift` - AppConstants (URLs, timeouts, defaults)
- `Utilities/Extensions.swift` - UserDefaults, Date, Color extensions

## Common Development Scenarios

### Adding a New Data Source
1. Create service class in `Services/` (follow YahooFinanceService pattern)
2. Add async methods returning model types
3. Integrate in UpdateManager for periodic updates
4. Update ViewModels to consume new data

### Adding Settings
1. Add property to UserDefaults extension in `Utilities/Extensions.swift`
2. Add UI in `Views/Settings/PreferencesView.swift` using @AppStorage
3. Access via DataManager getters/setters if business logic needed

### Modifying Portfolio Structure
1. Update `Models/Portfolio.swift` and `Models/Stock.swift`
2. Update JSON encoding/decoding in DataManager
3. Consider data migration for existing users
4. Update PortfolioViewModel calculations

### Changing Update Behavior
1. Modify `UpdateManager.startUpdating()` for timer logic
2. Adjust interval options in Constants.swift
3. Update PreferencesView to show new intervals
4. Consider market hours logic in `isMarketOpen()`

## Testing Notes

- No formal test suite currently exists
- Manual testing: Run app, check menu bar, verify updates, test settings persistence
- Test portfolio JSON by checking `~/Library/Application Support/StockStatus/`
- Test API calls by monitoring console for YahooFinanceService errors
- Test with invalid symbols to verify error handling

## Important Constraints

- **macOS only** - Uses NSStatusItem (no iOS equivalent)
- **No background execution** - App must be running for updates
- **Yahoo Finance dependency** - Breaking API changes will break app
- **~15 minute delay** - Yahoo Finance provides delayed quotes
- **Market hours** - Prices only update during trading hours (9:30 AM - 4:00 PM EST)
- **No authentication** - Yahoo Finance API is unauthenticated (could change)
- **LSUIElement = true** - App doesn't appear in Dock (menu bar only)

## Project Structure Context

The codebase follows standard Swift conventions with clear separation of concerns. Models are pure data structures with Codable conformance. Services handle all side effects (network, disk). ViewModels bridge services and views using Combine. Views are purely declarative SwiftUI with no business logic.

The hybrid AppKit/SwiftUI approach is necessary due to NSStatusItem limitations but is cleanly abstracted - StatusBarController is the only file that mixes both frameworks.
