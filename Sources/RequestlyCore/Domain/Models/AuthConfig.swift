import Foundation

public enum AuthType: String, CaseIterable, Codable, Identifiable {
    case none = "No Auth"
    case bearer = "Bearer Token"
    case basic = "Basic Auth"
    case apiKey = "API Key"
    case oauth2 = "OAuth 2.0"
    
    public var id: String { rawValue }
}

public enum APIKeyLocation: String, CaseIterable, Codable {
    case header = "Header"
    case queryParam = "Query Params"
}

public struct AuthConfig: Codable, Equatable {
    public var type: AuthType
    public var bearerToken: String
    public var basicUsername: String
    public var basicPassword: String
    public var apiKeyName: String
    public var apiKeyValue: String
    public var apiKeyLocation: APIKeyLocation
    public var oauthToken: String
    
    public init(
        type: AuthType = .none,
        bearerToken: String = "",
        basicUsername: String = "",
        basicPassword: String = "",
        apiKeyName: String = "X-API-Key",
        apiKeyValue: String = "",
        apiKeyLocation: APIKeyLocation = .header,
        oauthToken: String = ""
    ) {
        self.type = type
        self.bearerToken = bearerToken
        self.basicUsername = basicUsername
        self.basicPassword = basicPassword
        self.apiKeyName = apiKeyName
        self.apiKeyValue = apiKeyValue
        self.apiKeyLocation = apiKeyLocation
        self.oauthToken = oauthToken
    }
}
