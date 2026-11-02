import Foundation

public struct AppSettingsModel: Codable, Equatable {
    // Network Settings
    public var defaultTimeout: TimeInterval
    public var followRedirects: Bool
    public var validateSSL: Bool
    public var customUserAgent: String
    
    // Editor Settings
    public var editorFontSize: Double
    public var tabWidth: Int
    public var showLineNumbers: Bool
    public var wordWrap: Bool
    public var jsonIndentationSpaces: Int
    public var syntaxHighlightingEnabled: Bool
    
    // Response Settings
    public var maxResponseSizeMB: Int
    public var autoFormatJSON: Bool
    
    // Storage Settings
    public var historyRetentionDays: Int
    public var maxHistoryItems: Int
    
    public init(
        defaultTimeout: TimeInterval = 30.0,
        followRedirects: Bool = true,
        validateSSL: Bool = true,
        customUserAgent: String = "Requestly/1.0 (macOS)",
        editorFontSize: Double = 13.0,
        tabWidth: Int = 2,
        showLineNumbers: Bool = true,
        wordWrap: Bool = true,
        jsonIndentationSpaces: Int = 2,
        syntaxHighlightingEnabled: Bool = true,
        maxResponseSizeMB: Int = 50,
        autoFormatJSON: Bool = true,
        historyRetentionDays: Int = 30,
        maxHistoryItems: Int = 500
    ) {
        self.defaultTimeout = defaultTimeout
        self.followRedirects = followRedirects
        self.validateSSL = validateSSL
        self.customUserAgent = customUserAgent
        self.editorFontSize = editorFontSize
        self.tabWidth = tabWidth
        self.showLineNumbers = showLineNumbers
        self.wordWrap = wordWrap
        self.jsonIndentationSpaces = jsonIndentationSpaces
        self.syntaxHighlightingEnabled = syntaxHighlightingEnabled
        self.maxResponseSizeMB = maxResponseSizeMB
        self.autoFormatJSON = autoFormatJSON
        self.historyRetentionDays = historyRetentionDays
        self.maxHistoryItems = maxHistoryItems
    }
}
