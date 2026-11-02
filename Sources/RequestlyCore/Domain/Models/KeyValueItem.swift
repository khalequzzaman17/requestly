import Foundation

public struct KeyValueItem: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var key: String
    public var value: String
    public var description: String
    public var isEnabled: Bool
    
    public init(
        id: UUID = UUID(),
        key: String = "",
        value: String = "",
        description: String = "",
        isEnabled: Bool = true
    ) {
        self.id = id
        self.key = key
        self.value = value
        self.description = description
        self.isEnabled = isEnabled
    }
}
