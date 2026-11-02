import SwiftUI
import AppKit

public enum AppearanceManager {
    public static func enforceDarkMode() {
        NSApp.appearance = NSAppearance(named: .darkAqua)
    }
}

public struct DarkModeViewModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .preferredColorScheme(.dark)
            .environment(\.colorScheme, .dark)
    }
}

public extension View {
    func forceDarkMode() -> some View {
        modifier(DarkModeViewModifier())
    }
}
