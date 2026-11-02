import SwiftUI

public enum MethodColor {
    public static func color(for method: String) -> Color {
        switch method.uppercased() {
        case "GET":
            return Color(hex: 0x36C98F) // Green
        case "POST":
            return Color(hex: 0xE9B75C) // Yellow/Amber
        case "PUT":
            return Color(hex: 0xF39C12) // Orange
        case "PATCH":
            return Color(hex: 0x5685F7) // Blue
        case "DELETE":
            return Color(hex: 0xF07178) // Red
        case "HEAD":
            return Color(hex: 0xA855F7) // Purple
        case "OPTIONS":
            return Color(hex: 0x9E9E9E) // Gray
        default:
            return Color(hex: 0xA1A8B5) // Muted
        }
    }
    
    public static func background(for method: String) -> Color {
        color(for: method).opacity(0.15)
    }
}
