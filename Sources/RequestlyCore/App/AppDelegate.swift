import SwiftUI
import AppKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Enforce dark mode permanently across entire NSApplication
        AppearanceManager.enforceDarkMode()
        
        DispatchQueue.main.async {
            for window in NSApplication.shared.windows {
                window.title = "Requestly"
                window.backgroundColor = DarkTheme.nsMainBackground
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.toolbarStyle = .unified
            }
        }
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
