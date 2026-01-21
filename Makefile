.PHONY: all clean build install uninstall run zip help

# Default target
all: build

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@swift package clean
	@rm -rf StockStatus.app
	@rm -rf .build
	@echo "✅ Clean complete!"

# Build the app
build: clean
	@echo "🏗️  Building StockStatus..."
	@swift build -c release
	@echo "📦 Creating app bundle..."
	@mkdir -p StockStatus.app/Contents/{MacOS,Resources}
	@cp .build/release/StockStatus StockStatus.app/Contents/MacOS/
	@chmod +x StockStatus.app/Contents/MacOS/StockStatus
	@echo "📝 Creating Info.plist..."
	@printf '<?xml version="1.0" encoding="UTF-8"?>\n' > StockStatus.app/Contents/Info.plist
	@printf '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n' >> StockStatus.app/Contents/Info.plist
	@printf '<plist version="1.0">\n<dict>\n' >> StockStatus.app/Contents/Info.plist
	@printf '    <key>CFBundleDevelopmentRegion</key>\n    <string>en</string>\n' >> StockStatus.app/Contents/Info.plist
	@printf '    <key>CFBundleExecutable</key>\n    <string>StockStatus</string>\n' >> StockStatus.app/Contents/Info.plist
	@printf '    <key>CFBundleIdentifier</key>\n    <string>com.stockstatus.app</string>\n' >> StockStatus.app/Contents/Info.plist
	@printf '    <key>CFBundleInfoDictionaryVersion</key>\n    <string>6.0</string>\n' >> StockStatus.app/Contents/Info.plist
	@printf '    <key>CFBundleName</key>\n    <string>StockStatus</string>\n' >> StockStatus.app/Contents/Info.plist
	@printf '    <key>CFBundlePackageType</key>\n    <string>APPL</string>\n' >> StockStatus.app/Contents/Info.plist
	@printf '    <key>CFBundleShortVersionString</key>\n    <string>1.0</string>\n' >> StockStatus.app/Contents/Info.plist
	@printf '    <key>CFBundleVersion</key>\n    <string>1</string>\n' >> StockStatus.app/Contents/Info.plist
	@printf '    <key>CFBundleIconFile</key>\n    <string>AppIcon</string>\n' >> StockStatus.app/Contents/Info.plist
	@printf '    <key>LSMinimumSystemVersion</key>\n    <string>13.0</string>\n' >> StockStatus.app/Contents/Info.plist
	@printf '    <key>LSUIElement</key>\n    <true/>\n' >> StockStatus.app/Contents/Info.plist
	@printf '    <key>NSPrincipalClass</key>\n    <string>NSApplication</string>\n' >> StockStatus.app/Contents/Info.plist
	@printf '    <key>NSHumanReadableCopyright</key>\n    <string>Copyright © 2026. All rights reserved.</string>\n' >> StockStatus.app/Contents/Info.plist
	@printf '</dict>\n</plist>\n' >> StockStatus.app/Contents/Info.plist
	@if [ -f "StockStatus/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.icns" ]; then \
		cp StockStatus/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.icns StockStatus.app/Contents/Resources/; \
		echo "🎨 App icon copied"; \
	else \
		echo "⚠️  App icon not found"; \
	fi
	@echo "✅ Build complete!"

# Install to Applications folder
install: build
	@echo "📲 Installing StockStatus to /Applications..."
	@killall StockStatus 2>/dev/null || true
	@rm -rf /Applications/StockStatus.app
	@cp -r StockStatus.app /Applications/
	@echo "✅ Installed to /Applications/StockStatus.app"

# Uninstall from Applications folder
uninstall:
	@echo "🗑️  Uninstalling StockStatus..."
	@killall StockStatus 2>/dev/null || true
	@rm -rf /Applications/StockStatus.app
	@echo "✅ Uninstalled from /Applications"

# Run the app
run:
	@killall StockStatus 2>/dev/null || true
	@open StockStatus.app

# Create zip for distribution
zip: build
	@echo "📦 Creating distribution zip..."
	@zip -r StockStatus.zip StockStatus.app
	@echo "✅ Created StockStatus.zip"

# Show help
help:
	@echo "StockStatus Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make          - Build the app (default)"
	@echo "  make clean    - Remove build artifacts"
	@echo "  make build    - Clean and build the app"
	@echo "  make install  - Build and install to /Applications"
	@echo "  make uninstall- Remove from /Applications"
	@echo "  make run      - Run the app from current directory"
	@echo "  make zip      - Create distribution zip"
	@echo "  make help     - Show this help message"
