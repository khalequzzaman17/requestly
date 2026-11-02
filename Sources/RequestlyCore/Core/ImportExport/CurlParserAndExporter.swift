import Foundation

public final class CurlParserAndExporter {
    public static let shared = CurlParserAndExporter()
    
    public init() {}
    
    // MARK: - cURL Import
    
    public func parse(curlCommand: String) throws -> HTTPRequestModel {
        var command = curlCommand
            .replacingOccurrences(of: "\\\n", with: " ")
            .replacingOccurrences(of: "\\\r\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if command.hasPrefix("curl ") {
            command = String(command.dropFirst(5)).trimmingCharacters(in: .whitespaces)
        }
        
        var method: HTTPMethod = .get
        var urlString: String = ""
        var headers: [KeyValueItem] = []
        var bodyString: String = ""
        var auth = AuthConfig()
        var hasExplicitMethod = false
        
        let tokens = tokenize(command)
        var i = 0
        
        while i < tokens.count {
            let token = tokens[i]
            
            if token == "-X" || token == "--request" {
                if i + 1 < tokens.count {
                    i += 1
                    let m = tokens[i].uppercased()
                    if let parsedMethod = HTTPMethod(rawValue: m) {
                        method = parsedMethod
                        hasExplicitMethod = true
                    }
                }
            } else if token == "-H" || token == "--header" {
                if i + 1 < tokens.count {
                    i += 1
                    let headerLine = tokens[i]
                    if let colonIndex = headerLine.firstIndex(of: ":") {
                        let key = String(headerLine[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                        let val = String(headerLine[headerLine.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                        
                        if key.lowercased() == "authorization" {
                            if val.lowercased().hasPrefix("bearer ") {
                                auth.type = .bearer
                                auth.bearerToken = String(val.dropFirst(7)).trimmingCharacters(in: .whitespaces)
                            } else if val.lowercased().hasPrefix("basic ") {
                                auth.type = .basic
                                let base64 = String(val.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                                if let data = Data(base64Encoded: base64), let decoded = String(data: data, encoding: .utf8) {
                                    let parts = decoded.split(separator: ":", maxSplits: 1).map(String.init)
                                    auth.basicUsername = parts.first ?? ""
                                    auth.basicPassword = parts.count > 1 ? parts[1] : ""
                                }
                            } else {
                                headers.append(KeyValueItem(key: key, value: val, isEnabled: true))
                            }
                        } else {
                            headers.append(KeyValueItem(key: key, value: val, isEnabled: true))
                        }
                    }
                }
            } else if token == "-d" || token == "--data" || token == "--data-raw" || token == "--data-binary" {
                if i + 1 < tokens.count {
                    i += 1
                    bodyString = tokens[i]
                    if !hasExplicitMethod {
                        method = .post
                    }
                }
            } else if token == "-u" || token == "--user" {
                if i + 1 < tokens.count {
                    i += 1
                    let userPass = tokens[i]
                    let parts = userPass.split(separator: ":", maxSplits: 1).map(String.init)
                    auth.type = .basic
                    auth.basicUsername = parts.first ?? ""
                    auth.basicPassword = parts.count > 1 ? parts[1] : ""
                }
            } else if !token.hasPrefix("-") && urlString.isEmpty {
                urlString = token
            }
            i += 1
        }
        
        if urlString.isEmpty {
            throw NetworkError.invalidURL("No URL found in cURL command.")
        }
        
        let queryParams = URLValidator.extractQueryParams(from: urlString)
        let bodyType: RequestBodyType
        if bodyString.isEmpty {
            bodyType = .none
        } else if (try? JSONSerialization.jsonObject(with: bodyString.data(using: .utf8) ?? Data())) != nil {
            bodyType = .json
        } else {
            bodyType = .text
        }
        
        return HTTPRequestModel(
            name: "Imported cURL",
            method: method,
            url: urlString,
            queryParams: queryParams,
            headers: headers,
            bodyType: bodyType,
            rawBodyText: bodyString,
            auth: auth
        )
    }
    
    // MARK: - cURL Export
    
    public func export(request req: HTTPRequestModel, sanitizeSecrets: Bool = false) -> String {
        let request = sanitizeSecrets ? CredentialSanitizer.sanitize(request: req) : req
        var parts: [String] = ["curl"]
        
        // Method
        parts.append("-X \(request.method.rawValue)")
        
        // URL
        let resolvedURL = URLValidator.updateURL(request.url, withQueryParams: request.queryParams)
        parts.append(shellQuote(resolvedURL))
        
        // Headers
        for header in request.headers where header.isEnabled && !header.key.isEmpty {
            let headerString = "\(header.key): \(header.value)"
            parts.append("-H \(shellQuote(headerString))")
        }
        
        // Auth
        switch request.auth.type {
        case .none:
            break
        case .bearer:
            if !request.auth.bearerToken.isEmpty {
                parts.append("-H \(shellQuote("Authorization: Bearer \(request.auth.bearerToken)"))")
            }
        case .basic:
            parts.append("-u \(shellQuote("\(request.auth.basicUsername):\(request.auth.basicPassword)"))")
        case .apiKey:
            if request.auth.apiKeyLocation == .header && !request.auth.apiKeyName.isEmpty {
                parts.append("-H \(shellQuote("\(request.auth.apiKeyName): \(request.auth.apiKeyValue)"))")
            }
        case .oauth2:
            if !request.auth.oauthToken.isEmpty {
                parts.append("-H \(shellQuote("Authorization: Bearer \(request.auth.oauthToken)"))")
            }
        }
        
        // Body
        if request.method.hasBody {
            switch request.bodyType {
            case .none:
                break
            case .json, .text:
                if !request.rawBodyText.isEmpty {
                    parts.append("-d \(shellQuote(request.rawBodyText))")
                }
            case .urlEncoded:
                let enabledItems = request.urlEncodedItems.filter { $0.isEnabled && !$0.key.isEmpty }
                for item in enabledItems {
                    parts.append("--data-urlencode \(shellQuote("\(item.key)=\(item.value)"))")
                }
            case .formData:
                for item in request.formDataItems where item.isEnabled && !item.key.isEmpty {
                    if item.isFile, let path = item.filePath {
                        parts.append("-F \(shellQuote("\(item.key)=@\(path)"))")
                    } else {
                        parts.append("-F \(shellQuote("\(item.key)=\(item.value)"))")
                    }
                }
            case .binary:
                if let path = request.binaryFilePath {
                    parts.append("--data-binary \(shellQuote("@\(path)"))")
                }
            }
        }
        
        return parts.joined(separator: " \\\n  ")
    }
    
    private func shellQuote(_ string: String) -> String {
        return "'" + string.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
    
    // MARK: - Tokenizer helper
    
    private func tokenize(_ command: String) -> [String] {
        var tokens: [String] = []
        var currentToken = ""
        var inSingleQuotes = false
        var inDoubleQuotes = false
        var isEscaped = false
        
        for char in command {
            if isEscaped {
                currentToken.append(char)
                isEscaped = false
                continue
            }
            if char == "\\" {
                isEscaped = true
                continue
            }
            if char == "'" && !inDoubleQuotes {
                inSingleQuotes.toggle()
                continue
            }
            if char == "\"" && !inSingleQuotes {
                inDoubleQuotes.toggle()
                continue
            }
            if char.isWhitespace && !inSingleQuotes && !inDoubleQuotes {
                if !currentToken.isEmpty {
                    tokens.append(currentToken)
                    currentToken = ""
                }
            } else {
                currentToken.append(char)
            }
        }
        if !currentToken.isEmpty {
            tokens.append(currentToken)
        }
        return tokens
    }
}
