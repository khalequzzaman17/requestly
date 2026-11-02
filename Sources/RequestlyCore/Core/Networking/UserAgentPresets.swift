import Foundation

public struct UserAgentPreset: Identifiable, Hashable {
    public var id: String { name }
    public let name: String
    public let category: String
    public let userAgent: String
    
    public init(name: String, category: String, userAgent: String) {
        self.name = name
        self.category = category
        self.userAgent = userAgent
    }
}

public enum UserAgentPresets {
    public static let categories: [String] = [
        "API Clients",
        "Desktop Browsers",
        "Mobile Browsers",
        "Tablet Browsers"
    ]
    
    public static let presets: [UserAgentPreset] = [
        // Default / API Clients
        UserAgentPreset(name: "Requestly (Default)", category: "API Clients", userAgent: "Requestly/1.0 (macOS; Universal)"),
        UserAgentPreset(name: "cURL", category: "API Clients", userAgent: "curl/8.4.0"),
        UserAgentPreset(name: "PostmanRuntime", category: "API Clients", userAgent: "PostmanRuntime/7.39.0"),
        UserAgentPreset(name: "HTTPie", category: "API Clients", userAgent: "HTTPie/3.2.2"),
        
        // Desktop Browsers
        UserAgentPreset(name: "Google Chrome (macOS)", category: "Desktop Browsers", userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"),
        UserAgentPreset(name: "Apple Safari (macOS)", category: "Desktop Browsers", userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4.1 Safari/605.1.15"),
        UserAgentPreset(name: "Mozilla Firefox (macOS)", category: "Desktop Browsers", userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:125.0) Gecko/20100101 Firefox/125.0"),
        UserAgentPreset(name: "Microsoft Edge (macOS)", category: "Desktop Browsers", userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 Edg/124.0.0.0"),
        UserAgentPreset(name: "Google Chrome (Windows)", category: "Desktop Browsers", userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"),
        UserAgentPreset(name: "Microsoft Edge (Windows)", category: "Desktop Browsers", userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 Edg/124.0.0.0"),
        
        // Mobile Browsers
        UserAgentPreset(name: "iPhone - Safari (iOS 17)", category: "Mobile Browsers", userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1"),
        UserAgentPreset(name: "iPhone - Chrome", category: "Mobile Browsers", userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 17_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/124.0.6367.88 Mobile/15E148 Safari/604.1"),
        UserAgentPreset(name: "Android - Chrome (Pixel 8)", category: "Mobile Browsers", userAgent: "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.6367.54 Mobile Safari/537.36"),
        UserAgentPreset(name: "Android - Samsung Internet", category: "Mobile Browsers", userAgent: "Mozilla/5.0 (Linux; Android 14; SM-S928B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.230 Mobile Safari/537.36 SamsungBrowser/24.0"),
        
        // Tablet Browsers
        UserAgentPreset(name: "iPad - Safari (iPadOS 17)", category: "Tablet Browsers", userAgent: "Mozilla/5.0 (iPad; CPU OS 17_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1"),
        UserAgentPreset(name: "iPad - Chrome", category: "Tablet Browsers", userAgent: "Mozilla/5.0 (iPad; CPU OS 17_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/124.0.6367.88 Mobile/15E148 Safari/604.1"),
        UserAgentPreset(name: "Android Tablet (Galaxy Tab S9)", category: "Tablet Browsers", userAgent: "Mozilla/5.0 (Linux; Android 14; SM-X910) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.6367.54 Safari/537.36")
    ]
}
