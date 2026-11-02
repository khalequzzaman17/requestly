import Foundation

public extension Notification.Name {
    static let newRequestShortcut = Notification.Name("NewRequestShortcut")
    static let newTabShortcut = Notification.Name("NewTabShortcut")
    static let closeTabShortcut = Notification.Name("CloseTabShortcut")
    static let sendRequestShortcut = Notification.Name("SendRequestShortcut")
    static let cancelRequestShortcut = Notification.Name("CancelRequestShortcut")
    static let saveRequestShortcut = Notification.Name("SaveRequestShortcut")
    static let copyCurlShortcut = Notification.Name("CopyCurlShortcut")
    static let commandPaletteShortcut = Notification.Name("CommandPaletteShortcut")
    static let historyCleared = Notification.Name("HistoryClearedNotification")
}

