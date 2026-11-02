import Foundation

public struct HTTPResponseCookie: Identifiable, Codable, Equatable {
    public var id: String { "\(name)_\(domain)_\(path)" }
    public var name: String
    public var value: String
    public var domain: String
    public var path: String
    public var expiresDate: Date?
    public var isSecure: Bool
    public var isHTTPOnly: Bool
    
    public init(name: String, value: String, domain: String = "", path: String = "/", expiresDate: Date? = nil, isSecure: Bool = false, isHTTPOnly: Bool = false) {
        self.name = name
        self.value = value
        self.domain = domain
        self.path = path
        self.expiresDate = expiresDate
        self.isSecure = isSecure
        self.isHTTPOnly = isHTTPOnly
    }
}

public struct HTTPResponseModel: Identifiable, Codable, Equatable {
    public var id: UUID
    public var statusCode: Int
    public var statusDescription: String
    public var httpVersion: String
    public var headers: [String: String]
    public var headerList: [KeyValueItem]
    public var bodyData: Data
    public var durationMs: Double
    public var byteCount: Int
    public var effectiveURL: String
    public var errorDescription: String?
    public var cookies: [HTTPResponseCookie]
    public var timestamp: Date
    
    public init(
        id: UUID = UUID(),
        statusCode: Int = 200,
        statusDescription: String = "OK",
        httpVersion: String = "HTTP/1.1",
        headers: [String: String] = [:],
        headerList: [KeyValueItem] = [],
        bodyData: Data = Data(),
        durationMs: Double = 0.0,
        byteCount: Int = 0,
        effectiveURL: String = "",
        errorDescription: String? = nil,
        cookies: [HTTPResponseCookie] = [],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.statusCode = statusCode
        self.statusDescription = statusDescription
        self.httpVersion = httpVersion
        self.headers = headers
        self.headerList = headerList
        self.bodyData = bodyData
        self.durationMs = durationMs
        self.byteCount = byteCount
        self.effectiveURL = effectiveURL
        self.errorDescription = errorDescription
        self.cookies = cookies
        self.timestamp = timestamp
    }
    
    public var rawBodyString: String {
        String(data: bodyData, encoding: .utf8)
            ?? String(data: bodyData, encoding: .isoLatin1)
            ?? "<Binary data: \(bodyData.count) bytes>"
    }
    
    public var contentType: String {
        headers.first(where: { $0.key.caseInsensitiveCompare("content-type") == .orderedSame })?.value.lowercased() ?? ""
    }
    
    public var isJSON: Bool {
        if contentType.contains("application/json") ||
           contentType.contains("application/") && contentType.contains("+json") {
            return true
        }
        // Fallback detection strategy: try parsing non-empty data as JSON
        guard !bodyData.isEmpty else { return false }
        if let jsonObject = try? JSONSerialization.jsonObject(with: bodyData, options: []) {
            return jsonObject is [String: Any] || jsonObject is [Any]
        }
        return false
    }
    
    public var isHTML: Bool {
        contentType.contains("text/html")
    }
    
    public var isImage: Bool {
        contentType.contains("image/")
    }
    
    public var isSuccess: Bool {
        statusCode >= 200 && statusCode < 300
    }
}
