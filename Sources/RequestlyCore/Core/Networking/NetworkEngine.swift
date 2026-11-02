import Foundation

public final class NetworkSessionDelegate: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate, @unchecked Sendable {
    private let followRedirects: Bool
    private let validateSSL: Bool
    
    public init(followRedirects: Bool = true, validateSSL: Bool = true) {
        self.followRedirects = followRedirects
        self.validateSSL = validateSSL
        super.init()
    }
    
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        if followRedirects {
            // Security: Enforce safe HTTP / HTTPS scheme on redirect destination
            guard let scheme = request.url?.scheme?.lowercased(),
                  (scheme == "http" || scheme == "https") else {
                completionHandler(nil)
                return
            }
            // Security: Prevent HTTPS to plaintext HTTP downgrade attacks
            if let oldScheme = response.url?.scheme?.lowercased(), oldScheme == "https", scheme == "http" {
                completionHandler(nil)
                return
            }
            completionHandler(request)
        } else {
            completionHandler(nil)
        }
    }
    
    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if !validateSSL && challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
                return
            }
        }
        completionHandler(.performDefaultHandling, nil)
    }
}

public final class NetworkEngine: NetworkServiceProtocol, @unchecked Sendable {
    public static let shared = NetworkEngine()
    private var activeTasks: [UUID: URLSessionTask] = [:]
    private let lock = NSLock()
    
    public init() {}
    
    public func execute(request: HTTPRequestModel) async throws -> HTTPResponseModel {
        guard let url = URL(string: request.url) else {
            throw NetworkError.invalidURL(request.url)
        }
        
        // Build URL with query params
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let enabledQueryParams = request.queryParams.filter { $0.isEnabled && !$0.key.trimmingCharacters(in: .whitespaces).isEmpty }
        if !enabledQueryParams.isEmpty {
            var existingItems = urlComponents?.queryItems ?? []
            for item in enabledQueryParams {
                existingItems.append(URLQueryItem(name: item.key, value: item.value))
            }
            urlComponents?.queryItems = existingItems
        }
        
        // Handle API Key in query parameter if configured
        if request.auth.type == .apiKey && request.auth.apiKeyLocation == .queryParam && !request.auth.apiKeyName.isEmpty {
            var items = urlComponents?.queryItems ?? []
            items.append(URLQueryItem(name: request.auth.apiKeyName, value: request.auth.apiKeyValue))
            urlComponents?.queryItems = items
        }
        
        guard let finalURL = urlComponents?.url else {
            throw NetworkError.invalidURL(request.url)
        }
        
        var urlRequest = URLRequest(url: finalURL)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.timeoutInterval = request.timeoutInterval
        
        let settings = try? DatabaseService.shared.loadSettings()
        let trimWhitespace = settings?.trimWhitespaceInHeaders ?? true
        
        // Apply Headers
        for header in request.headers where header.isEnabled {
            let key = trimWhitespace ? header.key.trimmingCharacters(in: .whitespacesAndNewlines) : header.key
            let val = trimWhitespace ? header.value.trimmingCharacters(in: .whitespacesAndNewlines) : header.value
            if !key.isEmpty {
                urlRequest.setValue(val, forHTTPHeaderField: key)
            }
        }
        
        // Apply Default/Custom User-Agent if not explicitly specified in headers
        if urlRequest.value(forHTTPHeaderField: "User-Agent") == nil {
            let userAgent = settings?.customUserAgent.isEmpty == false ? (settings?.customUserAgent ?? "Requestly/1.0 (macOS; Universal)") : "Requestly/1.0 (macOS; Universal)"
            urlRequest.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        }
        
        // Apply Authentication
        switch request.auth.type {
        case .none:
            break
        case .bearer:
            if !request.auth.bearerToken.isEmpty {
                urlRequest.setValue("Bearer \(request.auth.bearerToken)", forHTTPHeaderField: "Authorization")
            }
        case .basic:
            let authString = "\(request.auth.basicUsername):\(request.auth.basicPassword)"
            if let authData = authString.data(using: .utf8) {
                let base64 = authData.base64EncodedString()
                urlRequest.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")
            }
        case .apiKey:
            if request.auth.apiKeyLocation == .header && !request.auth.apiKeyName.isEmpty {
                urlRequest.setValue(request.auth.apiKeyValue, forHTTPHeaderField: request.auth.apiKeyName)
            }
        case .oauth2:
            if !request.auth.oauthToken.isEmpty {
                urlRequest.setValue("Bearer \(request.auth.oauthToken)", forHTTPHeaderField: "Authorization")
            }
        }
        
        // Apply Body
        if request.method.hasBody {
            switch request.bodyType {
            case .none:
                break
            case .json:
                if let bodyData = request.rawBodyText.data(using: .utf8) {
                    urlRequest.httpBody = bodyData
                    if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    }
                }
            case .text:
                if let bodyData = request.rawBodyText.data(using: .utf8) {
                    urlRequest.httpBody = bodyData
                    if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                        urlRequest.setValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")
                    }
                }
            case .urlEncoded:
                let enabledItems = request.urlEncodedItems.filter { $0.isEnabled && !$0.key.isEmpty }
                var queryParts: [String] = []
                for item in enabledItems {
                    let escapedKey = item.key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? item.key
                    let escapedVal = item.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? item.value
                    queryParts.append("\(escapedKey)=\(escapedVal)")
                }
                let bodyString = queryParts.joined(separator: "&")
                urlRequest.httpBody = bodyString.data(using: .utf8)
                if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                    urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                }
            case .formData:
                let builder = MultipartFormDataBuilder()
                for item in request.formDataItems where item.isEnabled && !item.key.isEmpty {
                    if item.isFile, let path = item.filePath, FileManager.default.fileExists(atPath: path) {
                        let filename = URL(fileURLWithPath: path).lastPathComponent
                        let fileData = (try? Data(contentsOf: URL(fileURLWithPath: path))) ?? Data()
                        builder.addFile(name: item.key, filename: filename, mimeType: "application/octet-stream", fileData: fileData)
                    } else {
                        builder.addField(name: item.key, value: item.value)
                    }
                }
                let bodyData = builder.finalize()
                urlRequest.httpBody = bodyData
                urlRequest.setValue("multipart/form-data; boundary=\(builder.boundary)", forHTTPHeaderField: "Content-Type")
            case .binary:
                if let path = request.binaryFilePath, FileManager.default.fileExists(atPath: path) {
                    let fileData = try Data(contentsOf: URL(fileURLWithPath: path))
                    urlRequest.httpBody = fileData
                    if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                        urlRequest.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
                    }
                }
            }
        }
        
        let delegate = NetworkSessionDelegate(
            followRedirects: request.followRedirects,
            validateSSL: request.validateSSL
        )
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = request.timeoutInterval
        config.httpShouldSetCookies = true
        let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        return try await withTaskCancellationHandler {
            do {
                let (data, response) = try await session.data(for: urlRequest)
                let endTime = CFAbsoluteTimeGetCurrent()
                let durationMs = (endTime - startTime) * 1000.0
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    return HTTPResponseModel(
                        statusCode: 0,
                        statusDescription: "No HTTP Response",
                        httpVersion: "Unknown",
                        headers: [:],
                        headerList: [],
                        bodyData: data,
                        durationMs: durationMs,
                        byteCount: data.count,
                        effectiveURL: response.url?.absoluteString ?? request.url,
                        errorDescription: nil,
                        cookies: [],
                        timestamp: Date()
                    )
                }
                
                var headersDict: [String: String] = [:]
                var headerList: [KeyValueItem] = []
                for (key, value) in httpResponse.allHeaderFields {
                    let keyStr = String(describing: key)
                    let valStr = String(describing: value)
                    headersDict[keyStr] = valStr
                    headerList.append(KeyValueItem(key: keyStr, value: valStr, isEnabled: true))
                }
                
                headerList.sort { $0.key.lowercased() < $1.key.lowercased() }
                
                var cookies: [HTTPResponseCookie] = []
                if let url = response.url {
                    let parsedCookies = HTTPCookieStorage.shared.cookies(for: url) ?? []
                    cookies = parsedCookies.map { c in
                        HTTPResponseCookie(
                            name: c.name,
                            value: c.value,
                            domain: c.domain,
                            path: c.path,
                            expiresDate: c.expiresDate,
                            isSecure: c.isSecure,
                            isHTTPOnly: c.isHTTPOnly
                        )
                    }
                }
                
                let statusDesc = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                
                return HTTPResponseModel(
                    statusCode: httpResponse.statusCode,
                    statusDescription: statusDesc.capitalized,
                    httpVersion: "HTTP/1.1",
                    headers: headersDict,
                    headerList: headerList,
                    bodyData: data,
                    durationMs: durationMs,
                    byteCount: data.count,
                    effectiveURL: httpResponse.url?.absoluteString ?? request.url,
                    errorDescription: nil,
                    cookies: cookies,
                    timestamp: Date()
                )
            } catch {
                if (error as NSError).code == NSURLErrorCancelled {
                    throw NetworkError.cancelled
                } else if (error as NSError).code == NSURLErrorTimedOut {
                    throw NetworkError.timeout
                } else {
                    throw NetworkError.connectionFailed(error.localizedDescription)
                }
            }
        } onCancel: {
            self.cancel(requestId: request.id)
        }
    }
    
    public func cancel(requestId: UUID) {
        lock.lock()
        defer { lock.unlock() }
        activeTasks[requestId]?.cancel()
        activeTasks.removeValue(forKey: requestId)
    }
}
