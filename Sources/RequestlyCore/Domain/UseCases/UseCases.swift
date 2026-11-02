import Foundation

public final class VariableResolutionUseCase: EnvironmentResolverProtocol {
    public static let shared = VariableResolutionUseCase()
    
    public init() {}
    
    public func resolve(text: String, in environment: EnvironmentModel?) -> String {
        guard let env = environment else { return text }
        var result = text
        for variable in env.variables where variable.isEnabled && !variable.key.isEmpty {
            let placeholder = "{{\(variable.key)}}"
            result = result.replacingOccurrences(of: placeholder, with: variable.value)
        }
        return result
    }
    
    public func findUnresolvedVariables(in text: String, environment: EnvironmentModel?) -> [String] {
        let pattern = #"\{\{([a-zA-Z0-9_-]+)\}\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        
        var unresolved: [String] = []
        let availableKeys = Set(environment?.variables.filter { $0.isEnabled }.map { $0.key } ?? [])
        
        for match in matches {
            if match.numberOfRanges > 1 {
                let keyRange = match.range(at: 1)
                let key = nsText.substring(with: keyRange)
                if !availableKeys.contains(key) {
                    unresolved.append(key)
                }
            }
        }
        return Array(Set(unresolved))
    }
    
    public func resolve(request: HTTPRequestModel, in environment: EnvironmentModel?) -> HTTPRequestModel {
        guard let env = environment else { return request }
        var copy = request
        copy.url = resolve(text: copy.url, in: env)
        copy.queryParams = copy.queryParams.map {
            KeyValueItem(
                id: $0.id,
                key: resolve(text: $0.key, in: env),
                value: resolve(text: $0.value, in: env),
                description: $0.description,
                isEnabled: $0.isEnabled
            )
        }
        copy.headers = copy.headers.map {
            KeyValueItem(
                id: $0.id,
                key: resolve(text: $0.key, in: env),
                value: resolve(text: $0.value, in: env),
                description: $0.description,
                isEnabled: $0.isEnabled
            )
        }
        copy.rawBodyText = resolve(text: copy.rawBodyText, in: env)
        copy.urlEncodedItems = copy.urlEncodedItems.map {
            KeyValueItem(
                id: $0.id,
                key: resolve(text: $0.key, in: env),
                value: resolve(text: $0.value, in: env),
                description: $0.description,
                isEnabled: $0.isEnabled
            )
        }
        copy.formDataItems = copy.formDataItems.map {
            FormDataItem(
                id: $0.id,
                key: resolve(text: $0.key, in: env),
                value: resolve(text: $0.value, in: env),
                isFile: $0.isFile,
                filePath: $0.filePath,
                isEnabled: $0.isEnabled
            )
        }
        copy.auth.bearerToken = resolve(text: copy.auth.bearerToken, in: env)
        copy.auth.basicUsername = resolve(text: copy.auth.basicUsername, in: env)
        copy.auth.basicPassword = resolve(text: copy.auth.basicPassword, in: env)
        copy.auth.apiKeyName = resolve(text: copy.auth.apiKeyName, in: env)
        copy.auth.apiKeyValue = resolve(text: copy.auth.apiKeyValue, in: env)
        copy.auth.oauthToken = resolve(text: copy.auth.oauthToken, in: env)
        return copy
    }
}

public final class ExecuteRequestUseCase {
    private let networkEngine: NetworkServiceProtocol
    private let databaseService: DatabaseServiceProtocol
    private let variableResolver: VariableResolutionUseCase
    
    public init(
        networkEngine: NetworkServiceProtocol = NetworkEngine.shared,
        databaseService: DatabaseServiceProtocol = DatabaseService.shared,
        variableResolver: VariableResolutionUseCase = VariableResolutionUseCase.shared
    ) {
        self.networkEngine = networkEngine
        self.databaseService = databaseService
        self.variableResolver = variableResolver
    }
    
    public func execute(request: HTTPRequestModel, environment: EnvironmentModel?) async throws -> HTTPResponseModel {
        let resolvedRequest = variableResolver.resolve(request: request, in: environment)
        let response = try await networkEngine.execute(request: resolvedRequest)
        
        let historyItem = RequestHistoryItem(
            requestName: request.name,
            method: request.method,
            url: resolvedRequest.url,
            statusCode: response.statusCode,
            statusDescription: response.statusDescription,
            durationMs: response.durationMs,
            byteCount: response.byteCount,
            timestamp: Date(),
            requestSnapshot: request
        )
        try? databaseService.addHistoryItem(historyItem)
        
        return response
    }
}
