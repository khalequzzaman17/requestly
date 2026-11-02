import Foundation

public enum RequestBodyType: String, CaseIterable, Codable, Identifiable {
    case none = "None"
    case json = "JSON"
    case text = "Text"
    case formData = "Form Data"
    case urlEncoded = "x-www-form-urlencoded"
    case binary = "Binary"
    
    public var id: String { rawValue }
    
    public var contentType: String? {
        switch self {
        case .none:
            return nil
        case .json:
            return "application/json"
        case .text:
            return "text/plain; charset=utf-8"
        case .formData:
            return "multipart/form-data"
        case .urlEncoded:
            return "application/x-www-form-urlencoded"
        case .binary:
            return "application/octet-stream"
        }
    }
}

public struct FormDataItem: Identifiable, Codable, Equatable {
    public var id: UUID
    public var key: String
    public var value: String
    public var isFile: Bool
    public var filePath: String?
    public var isEnabled: Bool
    
    public init(
        id: UUID = UUID(),
        key: String = "",
        value: String = "",
        isFile: Bool = false,
        filePath: String? = nil,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.key = key
        self.value = value
        self.isFile = isFile
        self.filePath = filePath
        self.isEnabled = isEnabled
    }
}
