import Foundation

public enum ByteFormatter {
    public static func format(_ bytes: Int) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            let kb = Double(bytes) / 1024.0
            return String(format: "%.1f KB", kb)
        } else if bytes < 1024 * 1024 * 1024 {
            let mb = Double(bytes) / (1024.0 * 1024.0)
            return String(format: "%.2f MB", mb)
        } else {
            let gb = Double(bytes) / (1024.0 * 1024.0 * 1024.0)
            return String(format: "%.2f GB", gb)
        }
    }
}

public enum TimeFormatter {
    public static func formatDurationMs(_ ms: Double) -> String {
        if ms < 1000 {
            return "\(Int(ms.rounded())) ms"
        } else {
            let seconds = ms / 1000.0
            return String(format: "%.2f s", seconds)
        }
    }
    
    public static func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    public static func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

public enum URLValidator {
    public static func extractQueryParams(from urlString: String) -> [KeyValueItem] {
        guard let url = URL(string: urlString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return []
        }
        return queryItems.map {
            KeyValueItem(key: $0.name, value: $0.value ?? "", description: "", isEnabled: true)
        }
    }
    
    public static func updateURL(_ urlString: String, withQueryParams params: [KeyValueItem]) -> String {
        guard var components = URLComponents(string: urlString) else {
            return urlString
        }
        let enabledParams = params.filter { $0.isEnabled && !$0.key.trimmingCharacters(in: .whitespaces).isEmpty }
        if enabledParams.isEmpty {
            components.queryItems = nil
        } else {
            components.queryItems = enabledParams.map {
                URLQueryItem(name: $0.key, value: $0.value)
            }
        }
        return components.string ?? urlString
    }
    
    public static func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme != nil && url.host != nil
    }
}
