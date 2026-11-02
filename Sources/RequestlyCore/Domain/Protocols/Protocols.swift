import Foundation

public protocol NetworkServiceProtocol: Sendable {
    func execute(request: HTTPRequestModel) async throws -> HTTPResponseModel
    func cancel(requestId: UUID)
}

public protocol DatabaseServiceProtocol: AnyObject {
    func fetchCollections() throws -> [CollectionModel]
    func saveCollection(_ collection: CollectionModel) throws
    func deleteCollection(id: UUID) throws
    
    func fetchFolders(collectionId: UUID) throws -> [FolderModel]
    func saveFolder(_ folder: FolderModel) throws
    func deleteFolder(id: UUID) throws
    
    func fetchSavedRequests(collectionId: UUID?, folderId: UUID?) throws -> [SavedRequestModel]
    func saveRequest(_ request: SavedRequestModel) throws
    func deleteSavedRequest(id: UUID) throws
    
    func fetchEnvironments() throws -> [EnvironmentModel]
    func saveEnvironment(_ environment: EnvironmentModel) throws
    func deleteEnvironment(id: UUID) throws
    
    func fetchHistory(limit: Int) throws -> [RequestHistoryItem]
    func addHistoryItem(_ item: RequestHistoryItem) throws
    func clearHistory() throws
    
    func loadSettings() throws -> AppSettingsModel
    func saveSettings(_ settings: AppSettingsModel) throws
}

public protocol KeychainServiceProtocol: AnyObject {
    func storeSecret(_ secret: String, forKey key: String) throws
    func retrieveSecret(forKey key: String) throws -> String?
    func deleteSecret(forKey key: String) throws
}

public protocol EnvironmentResolverProtocol {
    func resolve(text: String, in environment: EnvironmentModel?) -> String
    func findUnresolvedVariables(in text: String, environment: EnvironmentModel?) -> [String]
}
