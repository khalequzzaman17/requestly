import SwiftUI

public enum SidebarSection: String, CaseIterable {
    case collections = "Collections"
    case history = "History"
}

@MainActor
public final class SidebarViewModel: ObservableObject {
    @Published public var collections: [CollectionModel] = []
    @Published public var folders: [FolderModel] = []
    @Published public var savedRequests: [SavedRequestModel] = []
    @Published public var historyItems: [RequestHistoryItem] = []
    
    @Published public var selectedSection: SidebarSection = .collections
    @Published public var searchQuery: String = ""
    @Published public var expandedCollectionIds: Set<UUID> = []
    @Published public var expandedFolderIds: Set<UUID> = []
    
    // Dialog states
    @Published public var showNewCollectionSheet: Bool = false
    @Published public var newCollectionName: String = ""
    @Published public var showNewFolderSheet: Bool = false
    @Published public var targetCollectionForFolder: CollectionModel? = nil
    @Published public var newFolderName: String = ""
    @Published public var showClearConfirmDialog: Bool = false
    @Published public var clearSuccessMessage: String? = nil
    
    private let databaseService: DatabaseServiceProtocol
    
    public var onSelectRequest: ((HTTPRequestModel) -> Void)? = nil
    public var onNewRequest: (() -> Void)? = nil
    public var onOpenEnvironments: (() -> Void)? = nil
    public var onOpenImport: (() -> Void)? = nil
    public var onOpenExport: (() -> Void)? = nil
    public var onOpenSettings: (() -> Void)? = nil
    
    public init(databaseService: DatabaseServiceProtocol = DatabaseService.shared) {
        self.databaseService = databaseService
        loadData()
        
        NotificationCenter.default.addObserver(forName: .historyCleared, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.loadHistory()
            }
        }
    }
    
    public func loadData() {
        do {
            self.collections = try databaseService.fetchCollections()
            self.historyItems = try databaseService.fetchHistory(limit: 100)
            
            var allFolders: [FolderModel] = []
            var allRequests: [SavedRequestModel] = []
            
            for coll in collections {
                let fList = try databaseService.fetchFolders(collectionId: coll.id)
                allFolders.append(contentsOf: fList)
                let rList = try databaseService.fetchSavedRequests(collectionId: coll.id, folderId: nil)
                allRequests.append(contentsOf: rList)
            }
            self.folders = allFolders
            self.savedRequests = allRequests
            
            // Default expand all collections
            for coll in collections {
                expandedCollectionIds.insert(coll.id)
            }
        } catch {
            print("Error loading sidebar data: \(error)")
        }
    }
    
    public func createCollection(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let coll = CollectionModel(name: trimmed)
        try? databaseService.saveCollection(coll)
        expandedCollectionIds.insert(coll.id)
        loadData()
    }
    
    public func deleteCollection(_ coll: CollectionModel) {
        try? databaseService.deleteCollection(id: coll.id)
        loadData()
    }
    
    public func createFolder(name: String, in collectionId: UUID, parentFolderId: UUID? = nil) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let folder = FolderModel(collectionId: collectionId, parentFolderId: parentFolderId, name: trimmed)
        try? databaseService.saveFolder(folder)
        expandedFolderIds.insert(folder.id)
        loadData()
    }
    
    public func deleteFolder(_ folder: FolderModel) {
        try? databaseService.deleteFolder(id: folder.id)
        loadData()
    }
    
    public func deleteRequest(_ request: SavedRequestModel) {
        try? databaseService.deleteSavedRequest(id: request.id)
        loadData()
    }
    
    public func duplicateRequest(_ request: SavedRequestModel) {
        var copy = request.request
        copy.id = UUID()
        copy.name = "\(copy.name) (Copy)"
        let newSaved = SavedRequestModel(collectionId: request.collectionId, folderId: request.folderId, request: copy)
        try? databaseService.saveRequest(newSaved)
        loadData()
    }
    
    public func loadHistory() {
        if let items = try? databaseService.fetchHistory(limit: 100) {
            self.historyItems = items
        } else {
            self.historyItems = []
        }
    }
    
    public func clearHistory() {
        try? databaseService.clearHistory()
        self.historyItems = []
        self.clearSuccessMessage = "Request history cleared"
        NotificationCenter.default.post(name: .historyCleared, object: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.clearSuccessMessage = nil
        }
    }
}
