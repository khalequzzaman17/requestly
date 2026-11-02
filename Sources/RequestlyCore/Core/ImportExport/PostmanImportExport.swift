import Foundation

public struct ImportedCollectionResult {
    public let collection: CollectionModel
    public let folders: [FolderModel]
    public let requests: [SavedRequestModel]
}

public final class PostmanCollectionParser {
    public static let shared = PostmanCollectionParser()
    
    public init() {}
    
    public func parse(data: Data) throws -> ImportedCollectionResult {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw JSONFormatterError.invalidData
        }
        
        let info = json["info"] as? [String: Any] ?? [:]
        let name = (info["name"] as? String) ?? "Imported Postman Collection"
        let desc = (info["description"] as? String) ?? ""
        
        let collectionId = UUID()
        let collection = CollectionModel(id: collectionId, name: name, description: desc)
        
        var folders: [FolderModel] = []
        var requests: [SavedRequestModel] = []
        
        if let items = json["item"] as? [[String: Any]] {
            parseItems(items, collectionId: collectionId, parentFolderId: nil, folders: &folders, requests: &requests)
        }
        
        return ImportedCollectionResult(collection: collection, folders: folders, requests: requests)
    }
    
    private func parseItems(
        _ items: [[String: Any]],
        collectionId: UUID,
        parentFolderId: UUID?,
        folders: inout [FolderModel],
        requests: inout [SavedRequestModel]
    ) {
        for (index, item) in items.enumerated() {
            let itemName = (item["name"] as? String) ?? "Untitled"
            
            // Check if it's a folder (has nested "item" array)
            if let nestedItems = item["item"] as? [[String: Any]] {
                let folderId = UUID()
                let folderDesc = (item["description"] as? String) ?? ""
                let folder = FolderModel(
                    id: folderId,
                    collectionId: collectionId,
                    parentFolderId: parentFolderId,
                    name: itemName,
                    description: folderDesc,
                    orderIndex: index
                )
                folders.append(folder)
                parseItems(nestedItems, collectionId: collectionId, parentFolderId: folderId, folders: &folders, requests: &requests)
            } else if let reqDict = item["request"] as? [String: Any] {
                // It's a request
                let parsedRequest = parseRequest(reqDict, name: itemName)
                let saved = SavedRequestModel(
                    collectionId: collectionId,
                    folderId: parentFolderId,
                    request: parsedRequest
                )
                requests.append(saved)
            }
        }
    }
    
    private func parseRequest(_ dict: [String: Any], name: String) -> HTTPRequestModel {
        let methodStr = (dict["method"] as? String)?.uppercased() ?? "GET"
        let method = HTTPMethod(rawValue: methodStr) ?? .get
        
        var urlString = ""
        var queryParams: [KeyValueItem] = []
        
        if let rawUrl = dict["url"] as? String {
            urlString = rawUrl
            queryParams = URLValidator.extractQueryParams(from: rawUrl)
        } else if let urlObj = dict["url"] as? [String: Any] {
            urlString = (urlObj["raw"] as? String) ?? ""
            if let queryArray = urlObj["query"] as? [[String: Any]] {
                queryParams = queryArray.compactMap { q in
                    guard let key = q["key"] as? String else { return nil }
                    let val = (q["value"] as? String) ?? ""
                    let desc = (q["description"] as? String) ?? ""
                    let disabled = (q["disabled"] as? Bool) ?? false
                    return KeyValueItem(key: key, value: val, description: desc, isEnabled: !disabled)
                }
            } else {
                queryParams = URLValidator.extractQueryParams(from: urlString)
            }
        }
        
        // Headers
        var headers: [KeyValueItem] = []
        if let headerArray = dict["header"] as? [[String: Any]] {
            headers = headerArray.compactMap { h in
                guard let key = h["key"] as? String else { return nil }
                let val = (h["value"] as? String) ?? ""
                let desc = (h["description"] as? String) ?? ""
                let disabled = (h["disabled"] as? Bool) ?? false
                return KeyValueItem(key: key, value: val, description: desc, isEnabled: !disabled)
            }
        }
        
        // Body
        var bodyType: RequestBodyType = .none
        var rawBody = ""
        var formDataItems: [FormDataItem] = []
        var urlEncodedItems: [KeyValueItem] = []
        
        if let bodyObj = dict["body"] as? [String: Any] {
            let mode = (bodyObj["mode"] as? String)?.lowercased() ?? ""
            switch mode {
            case "raw":
                rawBody = (bodyObj["raw"] as? String) ?? ""
                if let options = bodyObj["options"] as? [String: Any],
                   let rawOptions = options["raw"] as? [String: Any],
                   let lang = rawOptions["language"] as? String, lang.lowercased() == "json" {
                    bodyType = .json
                } else if (try? JSONSerialization.jsonObject(with: rawBody.data(using: .utf8) ?? Data())) != nil {
                    bodyType = .json
                } else {
                    bodyType = .text
                }
            case "urlencoded":
                bodyType = .urlEncoded
                if let urlEncoded = bodyObj["urlencoded"] as? [[String: Any]] {
                    urlEncodedItems = urlEncoded.compactMap { u in
                        guard let key = u["key"] as? String else { return nil }
                        let val = (u["value"] as? String) ?? ""
                        let disabled = (u["disabled"] as? Bool) ?? false
                        return KeyValueItem(key: key, value: val, isEnabled: !disabled)
                    }
                }
            case "formdata":
                bodyType = .formData
                if let fd = bodyObj["formdata"] as? [[String: Any]] {
                    formDataItems = fd.compactMap { f in
                        guard let key = f["key"] as? String else { return nil }
                        let val = (f["value"] as? String) ?? ""
                        let type = (f["type"] as? String) ?? "text"
                        let disabled = (f["disabled"] as? Bool) ?? false
                        return FormDataItem(key: key, value: val, isFile: type == "file", isEnabled: !disabled)
                    }
                }
            default:
                bodyType = .none
            }
        }
        
        // Auth
        var auth = AuthConfig()
        if let authObj = dict["auth"] as? [String: Any] {
            let type = (authObj["type"] as? String) ?? "noauth"
            switch type {
            case "bearer":
                auth.type = .bearer
                if let bearerArr = authObj["bearer"] as? [[String: Any]] {
                    let tokenEntry = bearerArr.first(where: { ($0["key"] as? String) == "token" })
                    auth.bearerToken = (tokenEntry?["value"] as? String) ?? ""
                }
            case "basic":
                auth.type = .basic
                if let basicArr = authObj["basic"] as? [[String: Any]] {
                    let userEntry = basicArr.first(where: { ($0["key"] as? String) == "username" })
                    let passEntry = basicArr.first(where: { ($0["key"] as? String) == "password" })
                    auth.basicUsername = (userEntry?["value"] as? String) ?? ""
                    auth.basicPassword = (passEntry?["value"] as? String) ?? ""
                }
            case "apikey":
                auth.type = .apiKey
                if let apiArr = authObj["apikey"] as? [[String: Any]] {
                    let keyEntry = apiArr.first(where: { ($0["key"] as? String) == "key" })
                    let valEntry = apiArr.first(where: { ($0["key"] as? String) == "value" })
                    auth.apiKeyName = (keyEntry?["value"] as? String) ?? "X-API-Key"
                    auth.apiKeyValue = (valEntry?["value"] as? String) ?? ""
                }
            default:
                auth.type = .none
            }
        }
        
        return HTTPRequestModel(
            name: name,
            method: method,
            url: urlString.isEmpty ? "https://httpbin.org/get" : urlString,
            queryParams: queryParams,
            headers: headers,
            bodyType: bodyType,
            rawBodyText: rawBody,
            formDataItems: formDataItems,
            urlEncodedItems: urlEncodedItems,
            auth: auth
        )
    }
}

public final class PostmanCollectionExporter {
    public static let shared = PostmanCollectionExporter()
    
    public init() {}
    
    public func export(collection: CollectionModel, folders: [FolderModel], requests: [SavedRequestModel]) throws -> Data {
        var postmanDict: [String: Any] = [
            "info": [
                "_postman_id": collection.id.uuidString,
                "name": collection.name,
                "description": collection.description,
                "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
            ]
        ]
        
        var rootItems: [[String: Any]] = []
        
        // Root requests (no folder)
        let rootRequests = requests.filter { $0.folderId == nil }
        for req in rootRequests {
            rootItems.append(formatRequestItem(req.request))
        }
        
        // Root folders
        let rootFolders = folders.filter { $0.parentFolderId == nil }
        for folder in rootFolders {
            rootItems.append(formatFolderItem(folder, allFolders: folders, allRequests: requests))
        }
        
        postmanDict["item"] = rootItems
        return try JSONSerialization.data(withJSONObject: postmanDict, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
    }
    
    private func formatFolderItem(_ folder: FolderModel, allFolders: [FolderModel], allRequests: [SavedRequestModel]) -> [String: Any] {
        var folderItems: [[String: Any]] = []
        
        let folderRequests = allRequests.filter { $0.folderId == folder.id }
        for req in folderRequests {
            folderItems.append(formatRequestItem(req.request))
        }
        
        let childFolders = allFolders.filter { $0.parentFolderId == folder.id }
        for child in childFolders {
            folderItems.append(formatFolderItem(child, allFolders: allFolders, allRequests: allRequests))
        }
        
        return [
            "name": folder.name,
            "description": folder.description,
            "item": folderItems
        ]
    }
    
    private func formatRequestItem(_ request: HTTPRequestModel) -> [String: Any] {
        var reqObj: [String: Any] = [
            "method": request.method.rawValue,
            "url": [
                "raw": request.url,
                "query": request.queryParams.map { [
                    "key": $0.key,
                    "value": $0.value,
                    "description": $0.description,
                    "disabled": !$0.isEnabled
                ]}
            ],
            "header": request.headers.map { [
                "key": $0.key,
                "value": $0.value,
                "description": $0.description,
                "disabled": !$0.isEnabled
            ]}
        ]
        
        if request.method.hasBody && request.bodyType != .none {
            var bodyObj: [String: Any] = [:]
            switch request.bodyType {
            case .json:
                bodyObj["mode"] = "raw"
                bodyObj["raw"] = request.rawBodyText
                bodyObj["options"] = ["raw": ["language": "json"]]
            case .text:
                bodyObj["mode"] = "raw"
                bodyObj["raw"] = request.rawBodyText
                bodyObj["options"] = ["raw": ["language": "text"]]
            case .urlEncoded:
                bodyObj["mode"] = "urlencoded"
                bodyObj["urlencoded"] = request.urlEncodedItems.map { [
                    "key": $0.key,
                    "value": $0.value,
                    "disabled": !$0.isEnabled
                ]}
            case .formData:
                bodyObj["mode"] = "formdata"
                bodyObj["formdata"] = request.formDataItems.map { [
                    "key": $0.key,
                    "value": $0.value,
                    "type": $0.isFile ? "file" : "text",
                    "disabled": !$0.isEnabled
                ]}
            default:
                break
            }
            reqObj["body"] = bodyObj
        }
        
        return [
            "name": request.name,
            "request": reqObj
        ]
    }
}
