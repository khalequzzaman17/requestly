import Foundation

public struct RequestlyCollectionArchive: Codable {
    public var version: String
    public var collection: CollectionModel
    public var folders: [FolderModel]
    public var requests: [SavedRequestModel]
    
    public init(
        version: String = "1.0",
        collection: CollectionModel,
        folders: [FolderModel],
        requests: [SavedRequestModel]
    ) {
        self.version = version
        self.collection = collection
        self.folders = folders
        self.requests = requests
    }
}

public final class RequestlyCollectionExportImport {
    public static let shared = RequestlyCollectionExportImport()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    public init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }
    
    public func export(collection: CollectionModel, folders: [FolderModel], requests: [SavedRequestModel], sanitizeSecrets: Bool = false) throws -> Data {
        let exportRequests = sanitizeSecrets ? requests.map { saved -> SavedRequestModel in
            var copy = saved
            copy.request = CredentialSanitizer.sanitize(request: saved.request)
            return copy
        } : requests
        
        let archive = RequestlyCollectionArchive(
            collection: collection,
            folders: folders,
            requests: exportRequests
        )
        return try encoder.encode(archive)
    }
    
    public func parse(data: Data) throws -> RequestlyCollectionArchive {
        return try decoder.decode(RequestlyCollectionArchive.self, from: data)
    }
}
