import SwiftUI
import AppKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationWillFinishLaunching(_ notification: Notification) {
        // Condition 1: Enforce Single-Instance: Only one instance of Requestly can exist/run at any time.
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
        
        // Condition 2: Automatically purge any legacy com.requestly.macos duplicates from system
        cleanLegacyDuplicates()
    }
    
    private func cleanLegacyDuplicates() {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser
        
        let legacyPaths = [
            home.appendingPathComponent("Library/Preferences/com.requestly.macos.plist").path,
            home.appendingPathComponent("Library/Caches/com.requestly.macos").path,
            home.appendingPathComponent("Library/HTTPStorages/com.requestly.macos").path,
            home.appendingPathComponent("Library/Saved Application State/com.requestly.macos.savedState").path,
            home.appendingPathComponent("Herd/requestly/build/universal").path
        ]
        
        for path in legacyPaths {
            if fileManager.fileExists(atPath: path) {
                try? fileManager.removeItem(atPath: path)
            }
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
                window.appearance = NSAppearance(named: .darkAqua)
            }
        }
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
