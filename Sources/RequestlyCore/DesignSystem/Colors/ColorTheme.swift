import SwiftUI
import AppKit

public enum DarkTheme {
    // Backgrounds
    public static let mainBackground = Color(hex: 0x111318)
    public static let sidebarBackground = Color(hex: 0x171A21)
    public static let editorBackground = Color(hex: 0x151820)
    public static let secondaryBackground = Color(hex: 0x1D222C)
    public static let elevatedBackground = Color(hex: 0x222733)
    public static let hoverBackground = Color(hex: 0x272D3B)
    public static let activeTabBackground = Color(hex: 0x1A1F29)
    
    // Borders
    public static let borderDefault = Color(hex: 0x2A303B)
    public static let borderSubtle = Color(hex: 0x242A34)
    public static let borderFocus = Color(hex: 0x5685F7)
    
    // Typography
    public static let textPrimary = Color(hex: 0xE8EAF0)
    public static let textSecondary = Color(hex: 0xA1A8B5)
    public static let textMuted = Color(hex: 0x727B8C)
    
    // Accents
    public static let primaryBlue = Color(hex: 0x5685F7)
    public static let successGreen = Color(hex: 0x36C98F)
    public static let warningYellow = Color(hex: 0xE9B75C)
    public static let errorRed = Color(hex: 0xF07178)
    public static let accentPurple = Color(hex: 0xA855F7)
    
    // NSColor counterparts for AppKit integration
    public static let nsMainBackground = NSColor(hex: 0x111318)
    public static let nsSidebarBackground = NSColor(hex: 0x171A21)
    public static let nsEditorBackground = NSColor(hex: 0x151820)
    public static let nsTextPrimary = NSColor(hex: 0xE8EAF0)
    public static let nsTextSecondary = NSColor(hex: 0xA1A8B5)
}

public extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

public extension NSColor {
    convenience init(hex: UInt, alpha: CGFloat = 1.0) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: alpha
        )
    }
}
