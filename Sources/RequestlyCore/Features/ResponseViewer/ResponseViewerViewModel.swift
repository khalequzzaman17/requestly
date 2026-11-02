import SwiftUI

public enum ResponseViewerTab: String, CaseIterable, Identifiable {
    case pretty = "Pretty"
    case raw = "Raw"
    case preview = "Preview"
    case headers = "Headers"
    case cookies = "Cookies"
    
    public var id: String { rawValue }
}

@MainActor
public final class ResponseViewerViewModel: ObservableObject {
    @Published public var response: HTTPResponseModel?
    @Published public var activeTab: ResponseViewerTab = .pretty
    @Published public var searchQuery: String = ""
    @Published public var isSearchVisible: Bool = false
    @Published public var wrapLines: Bool = true
    @Published public var viewMode: Int = 0 // 0 = Tree, 1 = Formatted Code
    @Published public var headerFilterQuery: String = ""
    
    // JSON Specific
    @Published public var formattedJSON: String = ""
    @Published public var jsonRootNode: JSONTreeNode? = nil
    @Published public var jsonParsingError: String? = nil
    
    public init(response: HTTPResponseModel? = nil) {
        self.response = response
        if let resp = response {
            processResponse(resp)
        }
    }
    
    public func setResponse(_ resp: HTTPResponseModel) {
        self.response = resp
        processResponse(resp)
    }
    
    public func clearResponse() {
        self.response = nil
        self.formattedJSON = ""
        self.jsonRootNode = nil
        self.jsonParsingError = nil
    }
    
    private func processResponse(_ resp: HTTPResponseModel) {
        if resp.isJSON {
            activeTab = .pretty
            switch JSONPrettyFormatter.shared.prettyPrint(data: resp.bodyData, indentSpaces: 2) {
            case .success(let formatted):
                self.formattedJSON = formatted
                self.jsonParsingError = nil
            case .failure(let err):
                self.formattedJSON = resp.rawBodyString
                self.jsonParsingError = err.localizedDescription
            }
            
            // Build collapsible tree
            do {
                self.jsonRootNode = try JSONTreeParser.shared.parse(data: resp.bodyData, defaultExpandedDepth: 3)
            } catch {
                self.jsonRootNode = nil
            }
        } else if resp.isHTML || resp.isImage {
            activeTab = .preview
            self.formattedJSON = ""
            self.jsonRootNode = nil
        } else {
            activeTab = .raw
            self.formattedJSON = ""
            self.jsonRootNode = nil
        }
    }
    
    public func expandAllJSON() {
        jsonRootNode?.setExpandedRecursively(true)
    }
    
    public func collapseAllJSON() {
        jsonRootNode?.setExpandedRecursively(false)
        jsonRootNode?.isExpanded = true // Keep root open
    }
    
    public func copyPrettyJSON() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(formattedJSON.isEmpty ? (response?.rawBodyString ?? "") : formattedJSON, forType: .string)
    }
    
    public func copyRawBody() {
        guard let resp = response else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(resp.rawBodyString, forType: .string)
    }
    
    public func downloadResponse() {
        guard let resp = response else { return }
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        let suggestedName = resp.isJSON ? "response.json" : (resp.isHTML ? "response.html" : "response.txt")
        savePanel.nameFieldStringValue = suggestedName
        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? resp.bodyData.write(to: url)
        }
    }
}
