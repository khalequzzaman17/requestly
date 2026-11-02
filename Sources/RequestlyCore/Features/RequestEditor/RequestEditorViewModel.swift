import SwiftUI

public enum RequestConfigTab: String, CaseIterable, Identifiable {
    case params = "Params"
    case headers = "Headers"
    case body = "Body"
    case auth = "Auth"
    case scripts = "Scripts"
    
    public var id: String { rawValue }
}

@MainActor
public final class RequestEditorViewModel: ObservableObject {
    @Published public var request: HTTPRequestModel
    @Published public var activeConfigTab: RequestConfigTab = .params
    @Published public var scriptTab: Int = 0
    @Published public var isExecuting: Bool = false
    @Published public var jsonValidationError: String? = nil
    
    public var onURLChange: ((String) -> Void)? = nil
    public var onExecute: (() -> Void)? = nil
    public var onCancel: (() -> Void)? = nil
    public var onSave: (() -> Void)? = nil
    
    public init(request: HTTPRequestModel = HTTPRequestModel()) {
        self.request = request
    }
    
    public func updateURLFromParams() {
        request.url = URLValidator.updateURL(request.url, withQueryParams: request.queryParams)
    }
    
    public func updateParamsFromURL() {
        let extracted = URLValidator.extractQueryParams(from: request.url)
        if !extracted.isEmpty {
            self.request.queryParams = extracted
        }
    }
    
    public func formatJSONBody() {
        guard request.bodyType == .json else { return }
        switch JSONPrettyFormatter.shared.prettyPrint(string: request.rawBodyText, indentSpaces: 2) {
        case .success(let formatted):
            request.rawBodyText = formatted
            jsonValidationError = nil
        case .failure(let err):
            jsonValidationError = err.localizedDescription
        }
    }
    
    public func minifyJSONBody() {
        guard request.bodyType == .json else { return }
        switch JSONPrettyFormatter.shared.minify(string: request.rawBodyText) {
        case .success(let minified):
            request.rawBodyText = minified
            jsonValidationError = nil
        case .failure(let err):
            jsonValidationError = err.localizedDescription
        }
    }
    
    public func addParam() {
        request.queryParams.append(KeyValueItem(key: "", value: "", description: "", isEnabled: true))
    }
    
    public func addHeader() {
        request.headers.append(KeyValueItem(key: "", value: "", description: "", isEnabled: true))
    }
    
    public func addUrlEncodedItem() {
        request.urlEncodedItems.append(KeyValueItem(key: "", value: "", description: "", isEnabled: true))
    }
    
    public func addFormDataItem() {
        request.formDataItems.append(FormDataItem(key: "", value: "", isFile: false, isEnabled: true))
    }
}
