import Foundation

public struct SavedRequestModel: Identifiable, Codable, Equatable {
    public var id: UUID
    public var collectionId: UUID
    public var folderId: UUID?
    public var request: HTTPRequestModel
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        collectionId: UUID,
        folderId: UUID? = nil,
        request: HTTPRequestModel,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.collectionId = collectionId
        self.folderId = folderId
        self.request = request
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct FolderModel: Identifiable, Codable, Equatable {
    public var id: UUID
    public var collectionId: UUID
    public var parentFolderId: UUID?
    public var name: String
    public var description: String
    public var orderIndex: Int
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        collectionId: UUID,
        parentFolderId: UUID? = nil,
        name: String,
        description: String = "",
        orderIndex: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.collectionId = collectionId
        self.parentFolderId = parentFolderId
        self.name = name
        self.description = description
        self.orderIndex = orderIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct CollectionModel: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var description: String
    public var orderIndex: Int
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        orderIndex: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.orderIndex = orderIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
