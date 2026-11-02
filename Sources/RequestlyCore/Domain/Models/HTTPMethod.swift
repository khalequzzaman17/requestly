import Foundation

public enum HTTPMethod: String, CaseIterable, Codable, Identifiable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
    case head = "HEAD"
    case options = "OPTIONS"
    
    public var id: String { rawValue }
    
    public var hasBody: Bool {
        switch self {
        case .post, .put, .patch, .delete:
            return true
        case .get, .head, .options:
            return false
        }
    }
}
