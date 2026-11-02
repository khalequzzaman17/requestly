import Foundation
import SwiftUI

public enum JSONNodeType: Equatable {
    case object(count: Int)
    case array(count: Int)
    case string(String)
    case number(String)
    case boolean(Bool)
    case null
    
    public var isExpandable: Bool {
        switch self {
        case .object, .array:
            return true
        default:
            return false
        }
    }
    
    public var summary: String {
        switch self {
        case .object(let count):
            return "{\(count) \(count == 1 ? "item" : "items")}"
        case .array(let count):
            return "[\(count) \(count == 1 ? "item" : "items")]"
        case .string(let str):
            return "\"\(str)\""
        case .number(let num):
            return num
        case .boolean(let b):
            return b ? "true" : "false"
        case .null:
            return "null"
        }
    }
}

public final class JSONTreeNode: Identifiable, ObservableObject {
    public let id = UUID()
    public let key: String?
    public let nodeType: JSONNodeType
    public let depth: Int
    @Published public var isExpanded: Bool
    public var children: [JSONTreeNode] = []
    
    public init(
        key: String?,
        nodeType: JSONNodeType,
        depth: Int = 0,
        isExpanded: Bool = true,
        children: [JSONTreeNode] = []
    ) {
        self.key = key
        self.nodeType = nodeType
        self.depth = depth
        self.isExpanded = isExpanded
        self.children = children
    }
    
    public func setExpandedRecursively(_ expanded: Bool) {
        self.isExpanded = expanded
        for child in children {
            child.setExpandedRecursively(expanded)
        }
    }
    
    public func matchesSearch(_ query: String) -> Bool {
        let q = query.lowercased()
        if let key = key, key.lowercased().contains(q) {
            return true
        }
        switch nodeType {
        case .string(let s):
            return s.lowercased().contains(q)
        case .number(let n):
            return n.lowercased().contains(q)
        case .boolean(let b):
            return String(b).contains(q)
        case .null:
            return "null".contains(q)
        default:
            return children.contains { $0.matchesSearch(q) }
        }
    }
}

public final class JSONTreeParser {
    public static let shared = JSONTreeParser()
    
    public init() {}
    
    public func parse(data: Data, defaultExpandedDepth: Int = 3) throws -> JSONTreeNode {
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        return buildNode(key: nil, value: jsonObject, depth: 0, defaultExpandedDepth: defaultExpandedDepth)
    }
    
    public func parse(string: String, defaultExpandedDepth: Int = 3) throws -> JSONTreeNode {
        guard let data = string.data(using: .utf8) else {
            throw JSONFormatterError.invalidData
        }
        return try parse(data: data, defaultExpandedDepth: defaultExpandedDepth)
    }
    
    private func buildNode(key: String?, value: Any, depth: Int, defaultExpandedDepth: Int) -> JSONTreeNode {
        // Security: Prevent stack overflow from excessively nested JSON payloads
        if depth > 64 {
            return JSONTreeNode(key: key, nodeType: .string("[Nesting depth exceeded maximum safety limit (64)]"), depth: depth, isExpanded: false)
        }
        
        let isExpanded = depth < defaultExpandedDepth
        
        if let dict = value as? [String: Any] {
            let sortedKeys = dict.keys.sorted()
            let children = sortedKeys.map { k in
                buildNode(key: k, value: dict[k]!, depth: depth + 1, defaultExpandedDepth: defaultExpandedDepth)
            }
            return JSONTreeNode(
                key: key,
                nodeType: .object(count: dict.count),
                depth: depth,
                isExpanded: isExpanded,
                children: children
            )
        } else if let array = value as? [Any] {
            let children = array.enumerated().map { idx, item in
                buildNode(key: "[\(idx)]", value: item, depth: depth + 1, defaultExpandedDepth: defaultExpandedDepth)
            }
            return JSONTreeNode(
                key: key,
                nodeType: .array(count: array.count),
                depth: depth,
                isExpanded: isExpanded,
                children: children
            )
        } else if let string = value as? String {
            return JSONTreeNode(key: key, nodeType: .string(string), depth: depth, isExpanded: false)
        } else if let num = value as? NSNumber {
            if CFGetTypeID(num) == CFBooleanGetTypeID() {
                return JSONTreeNode(key: key, nodeType: .boolean(num.boolValue), depth: depth, isExpanded: false)
            } else {
                return JSONTreeNode(key: key, nodeType: .number(num.stringValue), depth: depth, isExpanded: false)
            }
        } else if value is NSNull {
            return JSONTreeNode(key: key, nodeType: .null, depth: depth, isExpanded: false)
        } else {
            return JSONTreeNode(key: key, nodeType: .string(String(describing: value)), depth: depth, isExpanded: false)
        }
    }
}
