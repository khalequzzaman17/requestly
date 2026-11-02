import SwiftUI

public enum AppTypography {
    // UI Fonts (SF Pro)
    public static let title = Font.system(size: 16, weight: .semibold, design: .default)
    public static let headline = Font.system(size: 14, weight: .semibold, design: .default)
    public static let body = Font.system(size: 13, weight: .regular, design: .default)
    public static let bodyMedium = Font.system(size: 13, weight: .medium, design: .default)
    public static let caption = Font.system(size: 11, weight: .regular, design: .default)
    public static let captionMedium = Font.system(size: 11, weight: .medium, design: .default)
    public static let badge = Font.system(size: 10, weight: .bold, design: .default)
    
    // Monospaced Fonts (SF Mono)
    public static let code = Font.system(size: 12, weight: .regular, design: .monospaced)
    public static let codeBold = Font.system(size: 12, weight: .semibold, design: .monospaced)
    public static let codeSmall = Font.system(size: 11, weight: .regular, design: .monospaced)
    public static let methodBadge = Font.system(size: 11, weight: .bold, design: .monospaced)
}
