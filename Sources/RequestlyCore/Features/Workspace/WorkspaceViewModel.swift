import SwiftUI

public struct WorkspaceTab: Identifiable, Equatable {
    public let id: UUID
    public var request: HTTPRequestModel
    public var response: HTTPResponseModel?
    public var isDirty: Bool
    
    public init(id: UUID = UUID(), request: HTTPRequestModel = HTTPRequestModel(), response: HTTPResponseModel? = nil, isDirty: Bool = false) {
        self.id = id
        self.request = request
        self.response = response
        self.isDirty = isDirty
    }
}

@MainActor
public final class WorkspaceViewModel: ObservableObject {
    @Published public var tabs: [WorkspaceTab] = []
    @Published public var activeTabId: UUID = UUID()
    @Published public var isExecuting: Bool = false
    @Published public var activeEnvironment: EnvironmentModel? = nil
    @Published public var environments: [EnvironmentModel] = []
    
    // Modals
    @Published public var showEnvironmentsSheet: Bool = false
    @Published public var showImportSheet: Bool = false
    @Published public var showSettingsSheet: Bool = false
    @Published public var showCommandPalette: Bool = false
    @Published public var showSaveSheet: Bool = false
    
    // Sub-viewmodels
    public let sidebarViewModel: SidebarViewModel
    public let environmentViewModel: EnvironmentViewModel
    public var activeEditorViewModel: RequestEditorViewModel?
    public var activeResponseViewModel: ResponseViewerViewModel = ResponseViewerViewModel()
    
    private let executeRequestUseCase = ExecuteRequestUseCase()
    private let databaseService: DatabaseServiceProtocol = DatabaseService.shared
    
    public init() {
        self.sidebarViewModel = SidebarViewModel(databaseService: databaseService)
        self.environmentViewModel = EnvironmentViewModel(databaseService: databaseService)
        
        let initialTab = WorkspaceTab(request: HTTPRequestModel())
        self.tabs = [initialTab]
        self.activeTabId = initialTab.id
        
        setupCallbacks()
        loadEnvironments()
        updateActiveViewModels()
    }
    
    public var activeTab: WorkspaceTab? {
        tabs.first(where: { $0.id == activeTabId })
    }
    
    private func setupCallbacks() {
        sidebarViewModel.onSelectRequest = { [weak self] req in
            self?.openInNewOrCurrentTab(request: req)
        }
        sidebarViewModel.onNewRequest = { [weak self] in
            self?.newTab()
        }
        sidebarViewModel.onOpenEnvironments = { [weak self] in
            self?.showEnvironmentsSheet = true
        }
        sidebarViewModel.onOpenImport = { [weak self] in
            self?.showImportSheet = true
        }
        sidebarViewModel.onOpenSettings = { [weak self] in
            self?.showSettingsSheet = true
        }
    }
    
    public func loadEnvironments() {
        environmentViewModel.loadEnvironments()
        self.environments = environmentViewModel.environments
        self.activeEnvironment = environments.first(where: { $0.isSelected }) ?? environments.first
    }
    
    public func newTab() {
        let settings = try? databaseService.loadSettings()
        let defaultMethod = settings?.defaultMethod ?? "GET"
        let method = HTTPMethod(rawValue: defaultMethod) ?? .get
        let newTab = WorkspaceTab(request: HTTPRequestModel(name: "New Request", method: method))
        tabs.append(newTab)
        activeTabId = newTab.id
        updateActiveViewModels()
    }
    
    public func closeTab(id: UUID) {
        guard tabs.count > 1 else {
            // If only 1 tab left, reset it
            tabs = [WorkspaceTab(request: HTTPRequestModel())]
            activeTabId = tabs[0].id
            updateActiveViewModels()
            return
        }
        if let idx = tabs.firstIndex(where: { $0.id == id }) {
            tabs.remove(at: idx)
            if activeTabId == id {
                activeTabId = tabs[max(0, idx - 1)].id
            }
            updateActiveViewModels()
        }
    }
    
    public func openInNewOrCurrentTab(request: HTTPRequestModel) {
        if let current = activeTab, current.request.url == "https://httpbin.org/get" && !current.isDirty && current.response == nil {
            // Replace current pristine tab
            if let idx = tabs.firstIndex(where: { $0.id == current.id }) {
                tabs[idx].request = request
                tabs[idx].response = nil
                tabs[idx].isDirty = false
                updateActiveViewModels()
                return
            }
        }
        let tab = WorkspaceTab(request: request)
        tabs.append(tab)
        activeTabId = tab.id
        updateActiveViewModels()
    }
    
    public func updateActiveViewModels() {
        guard let tab = activeTab else { return }
        let editorVM = RequestEditorViewModel(request: tab.request)
        
        editorVM.onExecute = { [weak self] in
            self?.executeActiveRequest()
        }
        editorVM.onCancel = { [weak self] in
            self?.cancelActiveRequest()
        }
        editorVM.onSave = { [weak self] in
            self?.saveActiveRequest()
        }
        
        self.activeEditorViewModel = editorVM
        
        if let resp = tab.response {
            activeResponseViewModel.setResponse(resp)
        } else {
            activeResponseViewModel.clearResponse()
        }
    }
    
    public func executeActiveRequest() {
        guard let editorVM = activeEditorViewModel, !isExecuting else { return }
        let req = editorVM.request
        isExecuting = true
        editorVM.isExecuting = true
        
        Task {
            do {
                let response = try await executeRequestUseCase.execute(request: req, environment: activeEnvironment)
                await MainActor.run {
                    self.isExecuting = false
                    editorVM.isExecuting = false
                    if let idx = self.tabs.firstIndex(where: { $0.id == self.activeTabId }) {
                        self.tabs[idx].request = req
                        self.tabs[idx].response = response
                    }
                    self.activeResponseViewModel.setResponse(response)
                    self.sidebarViewModel.loadData()
                }
            } catch {
                await MainActor.run {
                    self.isExecuting = false
                    editorVM.isExecuting = false
                    let errorResponse = HTTPResponseModel(
                        statusCode: 0,
                        statusDescription: "Error",
                        headers: [:],
                        bodyData: (error.localizedDescription).data(using: .utf8) ?? Data(),
                        effectiveURL: req.url,
                        errorDescription: error.localizedDescription
                    )
                    if let idx = self.tabs.firstIndex(where: { $0.id == self.activeTabId }) {
                        self.tabs[idx].response = errorResponse
                    }
                    self.activeResponseViewModel.setResponse(errorResponse)
                }
            }
        }
    }
    
    public func cancelActiveRequest() {
        guard let editorVM = activeEditorViewModel else { return }
        NetworkEngine.shared.cancel(requestId: editorVM.request.id)
        isExecuting = false
        editorVM.isExecuting = false
    }
    
    public func saveActiveRequest() {
        guard let editorVM = activeEditorViewModel else { return }
        let req = editorVM.request
        
        if sidebarViewModel.collections.isEmpty {
            sidebarViewModel.createCollection(name: "Default Collection")
        }
        guard let coll = sidebarViewModel.collections.first else { return }
        
        let saved = SavedRequestModel(collectionId: coll.id, request: req)
        try? databaseService.saveRequest(saved)
        sidebarViewModel.loadData()
    }
    
    public func copyActiveRequestCurl() {
        guard let editorVM = activeEditorViewModel else { return }
        let shouldSanitize = (try? databaseService.loadSettings())?.sanitizeSecretsInCurl ?? false
        let curl = CurlParserAndExporter.shared.export(request: editorVM.request, sanitizeSecrets: shouldSanitize)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(curl, forType: .string)
    }
}
