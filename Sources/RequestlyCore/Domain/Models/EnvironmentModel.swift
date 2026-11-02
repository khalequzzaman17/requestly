import Foundation

public struct EnvironmentVariable: Identifiable, Codable, Equatable {
    public var id: UUID
    public var key: String
    public var value: String
    public var isSecret: Bool
    public var isEnabled: Bool
    
    public init(
        id: UUID = UUID(),
        key: String = "",
        value: String = "",
        isSecret: Bool = false,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.key = key
        self.value = value
        self.isSecret = isSecret
        self.isEnabled = isEnabled
    }
}

public struct EnvironmentModel: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var variables: [EnvironmentVariable]
    public var isSelected: Bool
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        variables: [EnvironmentVariable] = [],
        isSelected: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.variables = variables
        self.isSelected = isSelected
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
