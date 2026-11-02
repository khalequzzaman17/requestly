import Foundation

public struct HTTPRequestModel: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var method: HTTPMethod
    public var url: String
    public var queryParams: [KeyValueItem]
    public var headers: [KeyValueItem]
    public var bodyType: RequestBodyType
    public var rawBodyText: String
    public var formDataItems: [FormDataItem]
    public var urlEncodedItems: [KeyValueItem]
    public var binaryFilePath: String?
    public var auth: AuthConfig
    public var preRequestScript: String
    public var postResponseScript: String
    public var timeoutInterval: TimeInterval
    public var followRedirects: Bool
    public var validateSSL: Bool
    
    public init(
        id: UUID = UUID(),
        name: String = "Untitled Request",
        method: HTTPMethod = .get,
        url: String = "https://httpbin.org/get",
        queryParams: [KeyValueItem] = [],
        headers: [KeyValueItem] = [
            KeyValueItem(key: "User-Agent", value: "Requestly/1.0 (macOS)", description: "Client identity", isEnabled: true),
            KeyValueItem(key: "Accept", value: "*/*", description: "Accept all response types", isEnabled: true)
        ],
        bodyType: RequestBodyType = .none,
        rawBodyText: String = "",
        formDataItems: [FormDataItem] = [],
        urlEncodedItems: [KeyValueItem] = [],
        binaryFilePath: String? = nil,
        auth: AuthConfig = AuthConfig(),
        preRequestScript: String = "",
        postResponseScript: String = "",
        timeoutInterval: TimeInterval = 30.0,
        followRedirects: Bool = true,
        validateSSL: Bool = true
    ) {
        self.id = id
        self.name = name
        self.method = method
        self.url = url
        self.queryParams = queryParams
        self.headers = headers
        self.bodyType = bodyType
        self.rawBodyText = rawBodyText
        self.formDataItems = formDataItems
        self.urlEncodedItems = urlEncodedItems
        self.binaryFilePath = binaryFilePath
        self.auth = auth
        self.preRequestScript = preRequestScript
        self.postResponseScript = postResponseScript
        self.timeoutInterval = timeoutInterval
        self.followRedirects = followRedirects
        self.validateSSL = validateSSL
    }
}
