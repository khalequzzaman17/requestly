import SwiftUI
import AppKit
import RequestlyCore

@main
public struct RequestlyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    public init() {
        AppearanceManager.enforceDarkMode()
    }
    
    public var body: some Scene {
        WindowGroup {
            WorkspaceView()
                .frame(minWidth: 900, minHeight: 600)
                .background(DarkTheme.mainBackground)
                .forceDarkMode()
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            // Native macOS Menu Commands
            CommandGroup(replacing: .newItem) {
                Button("New Request") {
                    NotificationCenter.default.post(name: NSNotification.Name("NewRequestShortcut"), object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
                
                Button("New Tab") {
                    NotificationCenter.default.post(name: NSNotification.Name("NewTabShortcut"), object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command])
            }
            
            CommandMenu("Request") {
                Button("Send Request") {
                    NotificationCenter.default.post(name: NSNotification.Name("SendRequestShortcut"), object: nil)
                }
                .keyboardShortcut(.return, modifiers: [.command])
                
                Button("Cancel Request") {
                    NotificationCenter.default.post(name: NSNotification.Name("CancelRequestShortcut"), object: nil)
                }
                .keyboardShortcut(".", modifiers: [.command])
                
                Divider()
                
                Button("Copy as cURL") {
                    NotificationCenter.default.post(name: NSNotification.Name("CopyCurlShortcut"), object: nil)
                }
                .keyboardShortcut("c", modifiers: [.command, .option])
            }
        }
    }
}
