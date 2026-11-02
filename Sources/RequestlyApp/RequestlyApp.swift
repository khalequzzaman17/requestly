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
            // File / New / Tab Commands
            CommandGroup(replacing: .newItem) {
                Button("New Request") {
                    NotificationCenter.default.post(name: .newRequestShortcut, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
                
                Button("New Tab") {
                    NotificationCenter.default.post(name: .newTabShortcut, object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command])
                
                Button("Close Tab") {
                    NotificationCenter.default.post(name: .closeTabShortcut, object: nil)
                }
                .keyboardShortcut("w", modifiers: [.command])
                
                Divider()
                
                Button("Save Request") {
                    NotificationCenter.default.post(name: .saveRequestShortcut, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command])
            }
            
            // Request Execution Commands
            CommandMenu("Request") {
                Button("Send Request") {
                    NotificationCenter.default.post(name: .sendRequestShortcut, object: nil)
                }
                .keyboardShortcut(.return, modifiers: [.command])
                
                Button("Cancel Request") {
                    NotificationCenter.default.post(name: .cancelRequestShortcut, object: nil)
                }
                .keyboardShortcut(".", modifiers: [.command])
                
                Divider()
                
                Button("Copy as cURL") {
                    NotificationCenter.default.post(name: .copyCurlShortcut, object: nil)
                }
                .keyboardShortcut("c", modifiers: [.command, .option])
            }
            
            // View / Navigation Commands
            CommandMenu("View") {
                Button("Command Palette...") {
                    NotificationCenter.default.post(name: .commandPaletteShortcut, object: nil)
                }
                .keyboardShortcut("k", modifiers: [.command])
            }
        }
    }
}
