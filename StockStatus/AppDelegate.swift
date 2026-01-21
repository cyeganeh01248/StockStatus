import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    var updateManager: UpdateManager?
    var preferencesWindowController: PreferencesWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize managers
        updateManager = UpdateManager.shared

        // Set up status bar
        statusBarController = StatusBarController()

        // Start updating stock prices
        updateManager?.startUpdating()
    }

    func applicationWillTerminate(_ notification: Notification) {
        updateManager?.stopUpdating()
    }

    @MainActor
    @objc func openPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController()
        }

        // Ensure window is created and shown
        guard let window = preferencesWindowController?.window else {
            print("Error: Preferences window not created")
            return
        }

        // Make the app active and bring window to front
        NSApp.activate(ignoringOtherApps: true)
        window.center()
        window.makeKeyAndOrderFront(nil)

        print("Preferences window opened")
    }
}
