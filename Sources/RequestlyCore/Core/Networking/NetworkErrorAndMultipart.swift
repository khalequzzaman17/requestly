import Foundation

public enum NetworkError: LocalizedError {
    case invalidURL(String)
    case cancelled
    case timeout
    case connectionFailed(String)
    case sslCertificateError(String)
    case fileNotFound(String)
    case encodingFailed(String)
    case insecureSchemeBlocked(String)
    case responseTooLarge(Int)
    case unsafeRedirect(String)
    case fileAccessRestricted(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .cancelled:
            return "Request was cancelled."
        case .timeout:
            return "Request timed out."
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .sslCertificateError(let reason):
            return "SSL certificate validation failed: \(reason)"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .encodingFailed(let msg):
            return "Encoding error: \(msg)"
        case .insecureSchemeBlocked(let msg):
            return "Insecure protocol blocked: \(msg)"
        case .responseTooLarge(let maxMB):
            return "Response payload exceeded the configured maximum size limit (\(maxMB) MB). Execution safely halted."
        case .unsafeRedirect(let url):
            return "Unsafe redirection blocked: attempted redirect to \(url)"
        case .fileAccessRestricted(let reason):
            return "File access restricted: \(reason)"
        }
    }
}

public final class MultipartFormDataBuilder {
    public let boundary: String
    private var data = Data()
    
    public init(boundary: String = "Boundary-\(UUID().uuidString)") {
        self.boundary = boundary
    }
    
    public func addField(name: String, value: String) {
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(value)\r\n".data(using: .utf8)!)
    }
    
    public func addFile(name: String, filename: String, mimeType: String, fileData: Data) {
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        data.append(fileData)
        data.append("\r\n".data(using: .utf8)!)
    }
    
    public func finalize() -> Data {
        var finalData = data
        finalData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return finalData
    }
}
