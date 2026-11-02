import Foundation
import Security

public enum KeychainError: LocalizedError {
    case itemNotFound
    case duplicateItem
    case unexpectedData
    case unhandledError(status: OSStatus)
    
    public var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Item not found in macOS Keychain."
        case .duplicateItem:
            return "Item already exists in macOS Keychain."
        case .unexpectedData:
            return "Unexpected data format in macOS Keychain."
        case .unhandledError(let status):
            return "Keychain operation failed with status: \(status)"
        }
    }
}

public final class KeychainManager: KeychainServiceProtocol, @unchecked Sendable {
    public static let shared = KeychainManager()
    private let service = "com.requestly.macos.keychain"
    
    public init() {}
    
    public func storeSecret(_ secret: String, forKey key: String) throws {
        guard let data = secret.data(using: .utf8) else {
            throw KeychainError.unexpectedData
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        if status == errSecSuccess {
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: data
            ]
            let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.unhandledError(status: updateStatus)
            }
        } else if status == errSecItemNotFound {
            var newItem = query
            newItem[kSecValueData as String] = data
            let addStatus = SecItemAdd(newItem as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unhandledError(status: addStatus)
            }
        } else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    public func retrieveSecret(forKey key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess, let data = item as? Data else {
            throw KeychainError.unhandledError(status: status)
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    public func deleteSecret(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}

public enum CredentialSanitizer {
    public static func sanitize(headers: [KeyValueItem]) -> [KeyValueItem] {
        let sensitiveKeys = ["authorization", "proxy-authorization", "x-api-key", "api-key", "token", "secret", "cookie"]
        return headers.map { item in
            var sanitized = item
            if sensitiveKeys.contains(item.key.lowercased()) {
                sanitized.value = "••••••••"
            }
            return sanitized
        }
    }
    
    public static func sanitize(request: HTTPRequestModel) -> HTTPRequestModel {
        var copy = request
        copy.headers = sanitize(headers: copy.headers)
        if !copy.auth.bearerToken.isEmpty {
            copy.auth.bearerToken = "••••••••"
        }
        if !copy.auth.basicPassword.isEmpty {
            copy.auth.basicPassword = "••••••••"
        }
        if !copy.auth.apiKeyValue.isEmpty {
            copy.auth.apiKeyValue = "••••••••"
        }
        if !copy.auth.oauthToken.isEmpty {
            copy.auth.oauthToken = "••••••••"
        }
        return copy
    }
}
