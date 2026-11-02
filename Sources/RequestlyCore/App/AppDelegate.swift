import SwiftUI
import AppKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationWillFinishLaunching(_ notification: Notification) {
        // Enforce Single-Instance: Only one instance of Requestly can exist/run at any time.
        let bundleId = Bundle.main.bundleIdentifier ?? "com.requestly.sysninja"
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
        
        let existingInstances = runningApps.filter { $0.processIdentifier != currentPID }
        if let primaryInstance = existingInstances.first {
            // Activate and bring the already running instance to the front
            if #available(macOS 14.0, *) {
                primaryInstance.activate()
            } else {
                primaryInstance.activate(options: [.activateIgnoringOtherApps])
            }
            // Terminate this secondary duplicate instance immediately
            exit(0)
        }
    }
    
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
