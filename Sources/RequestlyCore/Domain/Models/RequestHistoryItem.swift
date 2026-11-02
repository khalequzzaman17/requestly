import Foundation

public struct RequestHistoryItem: Identifiable, Codable, Equatable {
    public var id: UUID
    public var requestName: String
    public var method: HTTPMethod
    public var url: String
    public var statusCode: Int
    public var statusDescription: String
    public var durationMs: Double
    public var byteCount: Int
    public var timestamp: Date
    public var requestSnapshot: HTTPRequestModel
    
    public init(
        id: UUID = UUID(),
        requestName: String = "",
        method: HTTPMethod,
        url: String,
        statusCode: Int,
        statusDescription: String,
        durationMs: Double,
        byteCount: Int,
        timestamp: Date = Date(),
        requestSnapshot: HTTPRequestModel
    ) {
        self.id = id
        self.requestName = requestName.isEmpty ? url : requestName
        self.method = method
        self.url = url
        self.statusCode = statusCode
        self.statusDescription = statusDescription
        self.durationMs = durationMs
        self.byteCount = byteCount
        self.timestamp = timestamp
        self.requestSnapshot = requestSnapshot
    }
}
