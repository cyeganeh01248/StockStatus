import Cocoa
import SwiftUI

class PreferencesWindowController: NSWindowController {
    convenience init() {
        // Create the window with proper configuration
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 550, height: 450),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "StockStatus Preferences"
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating  // Keep window on top

        self.init(window: window)

        // Create SwiftUI view and set as content
        let contentView = PreferencesView()
        let hostingView = NSHostingView(rootView: contentView)
        window.contentView = hostingView

        // Set minimum window size
        window.setContentSize(NSSize(width: 550, height: 450))
        window.minSize = NSSize(width: 500, height: 400)

        print("PreferencesWindowController initialized")
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)

        guard let window = window else {
            print("Error: No window to show")
            return
        }

        // Ensure window is visible
        window.center()
        window.makeKeyAndOrderFront(sender)
        NSApp.activate(ignoringOtherApps: true)

        print("Preferences window should now be visible")
    }
}
