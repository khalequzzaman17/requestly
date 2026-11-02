import SwiftUI
import AppKit

public enum AppearanceManager {
    public static func enforceDarkMode() {
        NSApplication.shared.appearance = NSAppearance(named: .darkAqua)
    }
}

public struct DarkWindowConfigurator: NSViewRepresentable {
    public init() {}
    
    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            configure(view: view)
        }
        return view
    }
    
    public func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configure(view: nsView)
        }
    }
    
    private func configure(view: NSView) {
        guard let window = view.window else { return }
        window.appearance = NSAppearance(named: .darkAqua)
        if let contentView = window.contentView {
            configureScrollers(in: contentView)
        }
    }
    
    private func configureScrollers(in parent: NSView) {
        parent.appearance = NSAppearance(named: .darkAqua)
        if let scrollView = parent as? NSScrollView {
            scrollView.appearance = NSAppearance(named: .darkAqua)
            scrollView.scrollerKnobStyle = .dark
            if let vScroller = scrollView.verticalScroller {
                vScroller.appearance = NSAppearance(named: .darkAqua)
                vScroller.knobStyle = .dark
            }
            if let hScroller = scrollView.horizontalScroller {
                hScroller.appearance = NSAppearance(named: .darkAqua)
                hScroller.knobStyle = .dark
            }
        }
        for subview in parent.subviews {
            configureScrollers(in: subview)
        }
    }
}

public struct DarkModeViewModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .preferredColorScheme(.dark)
            .environment(\.colorScheme, .dark)
            .background(DarkWindowConfigurator())
    }
}

public extension View {
    func forceDarkMode() -> some View {
        modifier(DarkModeViewModifier())
    }
}
