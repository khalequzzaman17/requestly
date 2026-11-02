import Foundation

public final class DatabaseService: DatabaseServiceProtocol {
    public static let shared: DatabaseService = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let requestlyDir = appSupport.appendingPathComponent("Requestly", isDirectory: true)
        try? FileManager.default.createDirectory(at: requestlyDir, withIntermediateDirectories: true)
        let dbPath = requestlyDir.appendingPathComponent("requestly.sqlite").path
        return try! DatabaseService(path: dbPath)
    }()
    
    private let db: SQLiteDatabase
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    public init(path: String) throws {
        self.db = try SQLiteDatabase(path: path)
        try runMigrations()
    }
    
    private func runMigrations() throws {
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS schema_migrations (
                version INTEGER PRIMARY KEY,
                applied_at REAL NOT NULL
            );
        """)
        
        let appliedRows = try db.query(sql: "SELECT version FROM schema_migrations;")
        let appliedVersions = Set(appliedRows.compactMap { $0["version"] as? Int })
        
        // Migration 1: Base Schema
        if !appliedVersions.contains(1) {
            try db.transaction {
                try db.execute(sql: """
                    CREATE TABLE collections (
                        id TEXT PRIMARY KEY,
                        name TEXT NOT NULL,
                        description TEXT NOT NULL DEFAULT '',
                        order_index INTEGER NOT NULL DEFAULT 0,
                        created_at REAL NOT NULL,
                        updated_at REAL NOT NULL
                    );
                    
                    CREATE TABLE folders (
                        id TEXT PRIMARY KEY,
                        collection_id TEXT NOT NULL,
                        parent_folder_id TEXT,
                        name TEXT NOT NULL,
                        description TEXT NOT NULL DEFAULT '',
                        order_index INTEGER NOT NULL DEFAULT 0,
                        created_at REAL NOT NULL,
                        updated_at REAL NOT NULL,
                        FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE,
                        FOREIGN KEY (parent_folder_id) REFERENCES folders(id) ON DELETE CASCADE
                    );
                    
                    CREATE TABLE saved_requests (
                        id TEXT PRIMARY KEY,
                        collection_id TEXT NOT NULL,
                        folder_id TEXT,
                        name TEXT NOT NULL,
                        request_json TEXT NOT NULL,
                        created_at REAL NOT NULL,
                        updated_at REAL NOT NULL,
                        FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE,
                        FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE CASCADE
                    );
                    
                    CREATE TABLE environments (
                        id TEXT PRIMARY KEY,
                        name TEXT NOT NULL,
                        is_selected INTEGER NOT NULL DEFAULT 0,
                        created_at REAL NOT NULL,
                        updated_at REAL NOT NULL
                    );
                    
                    CREATE TABLE environment_variables (
                        id TEXT PRIMARY KEY,
                        environment_id TEXT NOT NULL,
                        key TEXT NOT NULL,
                        value TEXT NOT NULL,
                        is_secret INTEGER NOT NULL DEFAULT 0,
                        is_enabled INTEGER NOT NULL DEFAULT 1,
                        FOREIGN KEY (environment_id) REFERENCES environments(id) ON DELETE CASCADE
                    );
                    
                    CREATE TABLE request_history (
                        id TEXT PRIMARY KEY,
                        request_name TEXT NOT NULL,
                        method TEXT NOT NULL,
                        url TEXT NOT NULL,
                        status_code INTEGER NOT NULL,
                        status_description TEXT NOT NULL,
                        duration_ms REAL NOT NULL,
                        byte_count INTEGER NOT NULL,
                        timestamp REAL NOT NULL,
                        request_snapshot TEXT NOT NULL
                    );
                    
                    CREATE INDEX idx_history_timestamp ON request_history(timestamp DESC);
                    
                    CREATE TABLE application_settings (
                        key TEXT PRIMARY KEY,
                        value TEXT NOT NULL
                    );
                    
                    INSERT INTO schema_migrations (version, applied_at)
                    VALUES (1, \(Date().timeIntervalSince1970));
                """)
            }
        }
    }
    
    // MARK: - Collections
    
    public func fetchCollections() throws -> [CollectionModel] {
        let rows = try db.query(sql: "SELECT * FROM collections ORDER BY order_index ASC, created_at ASC;")
        return rows.compactMap { row in
            guard let idStr = row["id"] as? String,
                  let id = UUID(uuidString: idStr),
                  let name = row["name"] as? String else { return nil }
            let desc = (row["description"] as? String) ?? ""
            let order = (row["order_index"] as? Int) ?? 0
            let created = Date(timeIntervalSince1970: (row["created_at"] as? Double) ?? 0)
            let updated = Date(timeIntervalSince1970: (row["updated_at"] as? Double) ?? 0)
            return CollectionModel(id: id, name: name, description: desc, orderIndex: order, createdAt: created, updatedAt: updated)
        }
    }
    
    public func saveCollection(_ collection: CollectionModel) throws {
        try db.executeUpdate(
            sql: """
                INSERT INTO collections (id, name, description, order_index, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    name = excluded.name,
                    description = excluded.description,
                    order_index = excluded.order_index,
                    updated_at = excluded.updated_at;
            """,
            params: [
                collection.id.uuidString,
                collection.name,
                collection.description,
                collection.orderIndex,
                collection.createdAt.timeIntervalSince1970,
                collection.updatedAt.timeIntervalSince1970
            ]
        )
    }
    
    public func deleteCollection(id: UUID) throws {
        try db.executeUpdate(sql: "DELETE FROM collections WHERE id = ?;", params: [id.uuidString])
    }
    
    // MARK: - Folders
    
    public func fetchFolders(collectionId: UUID) throws -> [FolderModel] {
        let rows = try db.query(
            sql: "SELECT * FROM folders WHERE collection_id = ? ORDER BY order_index ASC, created_at ASC;",
            params: [collectionId.uuidString]
        )
        return rows.compactMap { row in
            guard let idStr = row["id"] as? String,
                  let id = UUID(uuidString: idStr),
                  let collIdStr = row["collection_id"] as? String,
                  let collId = UUID(uuidString: collIdStr),
                  let name = row["name"] as? String else { return nil }
            let parentId = (row["parent_folder_id"] as? String).flatMap { UUID(uuidString: $0) }
            let desc = (row["description"] as? String) ?? ""
            let order = (row["order_index"] as? Int) ?? 0
            let created = Date(timeIntervalSince1970: (row["created_at"] as? Double) ?? 0)
            let updated = Date(timeIntervalSince1970: (row["updated_at"] as? Double) ?? 0)
            return FolderModel(id: id, collectionId: collId, parentFolderId: parentId, name: name, description: desc, orderIndex: order, createdAt: created, updatedAt: updated)
        }
    }
    
    public func saveFolder(_ folder: FolderModel) throws {
        try db.executeUpdate(
            sql: """
                INSERT INTO folders (id, collection_id, parent_folder_id, name, description, order_index, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    collection_id = excluded.collection_id,
                    parent_folder_id = excluded.parent_folder_id,
                    name = excluded.name,
                    description = excluded.description,
                    order_index = excluded.order_index,
                    updated_at = excluded.updated_at;
            """,
            params: [
                folder.id.uuidString,
                folder.collectionId.uuidString,
                folder.parentFolderId?.uuidString ?? NSNull(),
                folder.name,
                folder.description,
                folder.orderIndex,
                folder.createdAt.timeIntervalSince1970,
                folder.updatedAt.timeIntervalSince1970
            ]
        )
    }
    
    public func deleteFolder(id: UUID) throws {
        try db.executeUpdate(sql: "DELETE FROM folders WHERE id = ?;", params: [id.uuidString])
    }
    
    // MARK: - Saved Requests
    
    public func fetchSavedRequests(collectionId: UUID?, folderId: UUID?) throws -> [SavedRequestModel] {
        var sql = "SELECT * FROM saved_requests WHERE 1=1"
        var params: [Any] = []
        
        if let cid = collectionId {
            sql += " AND collection_id = ?"
            params.append(cid.uuidString)
        }
        if let fid = folderId {
            sql += " AND folder_id = ?"
            params.append(fid.uuidString)
        }
        sql += " ORDER BY created_at ASC;"
        
        let rows = try db.query(sql: sql, params: params)
        return rows.compactMap { row in
            guard let idStr = row["id"] as? String,
                  let id = UUID(uuidString: idStr),
                  let cidStr = row["collection_id"] as? String,
                  let cid = UUID(uuidString: cidStr),
                  let reqJson = row["request_json"] as? String,
                  let data = reqJson.data(using: .utf8),
                  let request = try? decoder.decode(HTTPRequestModel.self, from: data) else { return nil }
            let fid = (row["folder_id"] as? String).flatMap { UUID(uuidString: $0) }
            let created = Date(timeIntervalSince1970: (row["created_at"] as? Double) ?? 0)
            let updated = Date(timeIntervalSince1970: (row["updated_at"] as? Double) ?? 0)
            return SavedRequestModel(id: id, collectionId: cid, folderId: fid, request: request, createdAt: created, updatedAt: updated)
        }
    }
    
    public func saveRequest(_ request: SavedRequestModel) throws {
        let reqData = try encoder.encode(request.request)
        let reqJson = String(data: reqData, encoding: .utf8) ?? "{}"
        try db.executeUpdate(
            sql: """
                INSERT INTO saved_requests (id, collection_id, folder_id, name, request_json, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    collection_id = excluded.collection_id,
                    folder_id = excluded.folder_id,
                    name = excluded.name,
                    request_json = excluded.request_json,
                    updated_at = excluded.updated_at;
            """,
            params: [
                request.id.uuidString,
                request.collectionId.uuidString,
                request.folderId?.uuidString ?? NSNull(),
                request.request.name,
                reqJson,
                request.createdAt.timeIntervalSince1970,
                request.updatedAt.timeIntervalSince1970
            ]
        )
    }
    
    public func deleteSavedRequest(id: UUID) throws {
        try db.executeUpdate(sql: "DELETE FROM saved_requests WHERE id = ?;", params: [id.uuidString])
    }
    
    // MARK: - Environments
    
    public func fetchEnvironments() throws -> [EnvironmentModel] {
        let envRows = try db.query(sql: "SELECT * FROM environments ORDER BY created_at ASC;")
        var environments: [EnvironmentModel] = []
        
        for envRow in envRows {
            guard let idStr = envRow["id"] as? String,
                  let id = UUID(uuidString: idStr),
                  let name = envRow["name"] as? String else { continue }
            let isSelected = ((envRow["is_selected"] as? Int) ?? 0) == 1
            let created = Date(timeIntervalSince1970: (envRow["created_at"] as? Double) ?? 0)
            let updated = Date(timeIntervalSince1970: (envRow["updated_at"] as? Double) ?? 0)
            
            let varRows = try db.query(
                sql: "SELECT * FROM environment_variables WHERE environment_id = ?;",
                params: [idStr]
            )
            let variables: [EnvironmentVariable] = varRows.compactMap { vr in
                guard let vidStr = vr["id"] as? String,
                      let vid = UUID(uuidString: vidStr),
                      let key = vr["key"] as? String,
                      let value = vr["value"] as? String else { return nil }
                let isSecret = ((vr["is_secret"] as? Int) ?? 0) == 1
                let isEnabled = ((vr["is_enabled"] as? Int) ?? 1) == 1
                return EnvironmentVariable(id: vid, key: key, value: value, isSecret: isSecret, isEnabled: isEnabled)
            }
            
            environments.append(EnvironmentModel(id: id, name: name, variables: variables, isSelected: isSelected, createdAt: created, updatedAt: updated))
        }
        return environments
    }
    
    public func saveEnvironment(_ environment: EnvironmentModel) throws {
        try db.transaction {
            try db.executeUpdate(
                sql: """
                    INSERT INTO environments (id, name, is_selected, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?)
                    ON CONFLICT(id) DO UPDATE SET
                        name = excluded.name,
                        is_selected = excluded.is_selected,
                        updated_at = excluded.updated_at;
                """,
                params: [
                    environment.id.uuidString,
                    environment.name,
                    environment.isSelected ? 1 : 0,
                    environment.createdAt.timeIntervalSince1970,
                    environment.updatedAt.timeIntervalSince1970
                ]
            )
            
            // Sync variables
            try db.executeUpdate(
                sql: "DELETE FROM environment_variables WHERE environment_id = ?;",
                params: [environment.id.uuidString]
            )
            
            for v in environment.variables {
                try db.executeUpdate(
                    sql: """
                        INSERT INTO environment_variables (id, environment_id, key, value, is_secret, is_enabled)
                        VALUES (?, ?, ?, ?, ?, ?);
                    """,
                    params: [
                        v.id.uuidString,
                        environment.id.uuidString,
                        v.key,
                        v.value,
                        v.isSecret ? 1 : 0,
                        v.isEnabled ? 1 : 0
                    ]
                )
            }
        }
    }
    
    public func deleteEnvironment(id: UUID) throws {
        try db.executeUpdate(sql: "DELETE FROM environments WHERE id = ?;", params: [id.uuidString])
    }
    
    // MARK: - History
    
    public func fetchHistory(limit: Int = 100) throws -> [RequestHistoryItem] {
        let rows = try db.query(
            sql: "SELECT * FROM request_history ORDER BY timestamp DESC LIMIT ?;",
            params: [limit]
        )
        return rows.compactMap { row in
            guard let idStr = row["id"] as? String,
                  let id = UUID(uuidString: idStr),
                  let name = row["request_name"] as? String,
                  let methodStr = row["method"] as? String,
                  let method = HTTPMethod(rawValue: methodStr),
                  let url = row["url"] as? String,
                  let statusCode = row["status_code"] as? Int,
                  let desc = row["status_description"] as? String,
                  let duration = row["duration_ms"] as? Double,
                  let bytes = row["byte_count"] as? Int,
                  let timeVal = row["timestamp"] as? Double,
                  let snapJson = row["request_snapshot"] as? String,
                  let snapData = snapJson.data(using: .utf8),
                  let snap = try? decoder.decode(HTTPRequestModel.self, from: snapData) else { return nil }
            return RequestHistoryItem(
                id: id,
                requestName: name,
                method: method,
                url: url,
                statusCode: statusCode,
                statusDescription: desc,
                durationMs: duration,
                byteCount: bytes,
                timestamp: Date(timeIntervalSince1970: timeVal),
                requestSnapshot: snap
            )
        }
    }
    
    public func addHistoryItem(_ item: RequestHistoryItem) throws {
        let snapData = (try? encoder.encode(item.requestSnapshot)) ?? Data()
        let snapJson = String(data: snapData, encoding: .utf8) ?? "{}"
        try db.executeUpdate(
            sql: """
                INSERT INTO request_history (id, request_name, method, url, status_code, status_description, duration_ms, byte_count, timestamp, request_snapshot)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """,
            params: [
                item.id.uuidString,
                item.requestName,
                item.method.rawValue,
                item.url,
                item.statusCode,
                item.statusDescription,
                item.durationMs,
                item.byteCount,
                item.timestamp.timeIntervalSince1970,
                snapJson
            ]
        )
    }
    
    public func clearHistory() throws {
        try db.executeUpdate(sql: "DELETE FROM request_history;")
    }
    
    // MARK: - Settings
    
    public func loadSettings() throws -> AppSettingsModel {
        let rows = try db.query(sql: "SELECT value FROM application_settings WHERE key = 'app_settings';")
        if let first = rows.first,
           let jsonStr = first["value"] as? String,
           let data = jsonStr.data(using: .utf8),
           let settings = try? decoder.decode(AppSettingsModel.self, from: data) {
            return settings
        }
        return AppSettingsModel()
    }
    
    public func saveSettings(_ settings: AppSettingsModel) throws {
        let data = try encoder.encode(settings)
        let jsonStr = String(data: data, encoding: .utf8) ?? "{}"
        try db.executeUpdate(
            sql: """
                INSERT INTO application_settings (key, value)
                VALUES ('app_settings', ?)
                ON CONFLICT(key) DO UPDATE SET value = excluded.value;
            """,
            params: [jsonStr]
        )
    }
}
