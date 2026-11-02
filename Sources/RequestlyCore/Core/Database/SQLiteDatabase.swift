import Foundation
import SQLite3

public enum SQLiteError: LocalizedError {
    case openDatabaseFailed(String)
    case prepareFailed(String)
    case stepFailed(String)
    case bindFailed(String)
    case executionFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .openDatabaseFailed(let msg):
            return "Failed to open SQLite database: \(msg)"
        case .prepareFailed(let msg):
            return "Failed to prepare SQLite statement: \(msg)"
        case .stepFailed(let msg):
            return "Failed to execute SQLite step: \(msg)"
        case .bindFailed(let msg):
            return "Failed to bind SQLite parameter: \(msg)"
        case .executionFailed(let msg):
            return "SQLite execution error: \(msg)"
        }
    }
}

public final class SQLiteDatabase {
    private var db: OpaquePointer?
    private let path: String
    private let lock = NSLock()
    
    public init(path: String) throws {
        self.path = path
        var dbPointer: OpaquePointer?
        if sqlite3_open_v2(path, &dbPointer, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil) != SQLITE_OK {
            let errorMsg = dbPointer != nil ? String(cString: sqlite3_errmsg(dbPointer)) : "Unknown"
            sqlite3_close(dbPointer)
            throw SQLiteError.openDatabaseFailed(errorMsg)
        }
        self.db = dbPointer
        try execute(sql: "PRAGMA foreign_keys = ON;")
        try execute(sql: "PRAGMA journal_mode = WAL;")
    }
    
    deinit {
        if let db = db {
            sqlite3_close(db)
        }
    }
    
    public func execute(sql: String) throws {
        lock.lock()
        defer { lock.unlock() }
        
        var errorMsg: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &errorMsg) != SQLITE_OK {
            let message = errorMsg != nil ? String(cString: errorMsg!) : "Unknown error"
            sqlite3_free(errorMsg)
            throw SQLiteError.executionFailed(message)
        }
    }
    
    public func transaction<T>(_ block: () throws -> T) throws -> T {
        try execute(sql: "BEGIN TRANSACTION;")
        do {
            let result = try block()
            try execute(sql: "COMMIT;")
            return result
        } catch {
            try? execute(sql: "ROLLBACK;")
            throw error
        }
    }
    
    public func query(sql: String, params: [Any] = []) throws -> [[String: Any]] {
        lock.lock()
        defer { lock.unlock() }
        
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) != SQLITE_OK {
            let msg = String(cString: sqlite3_errmsg(db))
            throw SQLiteError.prepareFailed(msg)
        }
        defer { sqlite3_finalize(stmt) }
        
        try bind(params: params, to: stmt)
        
        var results: [[String: Any]] = []
        let columnCount = sqlite3_column_count(stmt)
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            var row: [String: Any] = [:]
            for i in 0..<columnCount {
                let colName = String(cString: sqlite3_column_name(stmt, i))
                let colType = sqlite3_column_type(stmt, i)
                switch colType {
                case SQLITE_INTEGER:
                    row[colName] = Int(sqlite3_column_int64(stmt, i))
                case SQLITE_FLOAT:
                    row[colName] = sqlite3_column_double(stmt, i)
                case SQLITE_TEXT:
                    if let text = sqlite3_column_text(stmt, i) {
                        row[colName] = String(cString: text)
                    } else {
                        row[colName] = ""
                    }
                case SQLITE_BLOB:
                    if let blob = sqlite3_column_blob(stmt, i) {
                        let bytes = sqlite3_column_bytes(stmt, i)
                        row[colName] = Data(bytes: blob, count: Int(bytes))
                    } else {
                        row[colName] = Data()
                    }
                case SQLITE_NULL:
                    row[colName] = NSNull()
                default:
                    break
                }
            }
            results.append(row)
        }
        
        return results
    }
    
    public func executeUpdate(sql: String, params: [Any] = []) throws {
        lock.lock()
        defer { lock.unlock() }
        
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) != SQLITE_OK {
            let msg = String(cString: sqlite3_errmsg(db))
            throw SQLiteError.prepareFailed(msg)
        }
        defer { sqlite3_finalize(stmt) }
        
        try bind(params: params, to: stmt)
        
        let stepResult = sqlite3_step(stmt)
        if stepResult != SQLITE_DONE && stepResult != SQLITE_ROW {
            let msg = String(cString: sqlite3_errmsg(db))
            throw SQLiteError.stepFailed(msg)
        }
    }
    
    private func bind(params: [Any], to stmt: OpaquePointer?) throws {
        for (index, param) in params.enumerated() {
            let col = Int32(index + 1)
            if let stringVal = param as? String {
                sqlite3_bind_text(stmt, col, (stringVal as NSString).utf8String, -1, nil)
            } else if let intVal = param as? Int {
                sqlite3_bind_int64(stmt, col, Int64(intVal))
            } else if let doubleVal = param as? Double {
                sqlite3_bind_double(stmt, col, doubleVal)
            } else if let dataVal = param as? Data {
                _ = dataVal.withUnsafeBytes { buffer in
                    sqlite3_bind_blob(stmt, col, buffer.baseAddress, Int32(dataVal.count), nil)
                }
            } else if let boolVal = param as? Bool {
                sqlite3_bind_int(stmt, col, boolVal ? 1 : 0)
            } else if param is NSNull {
                sqlite3_bind_null(stmt, col)
            } else {
                sqlite3_bind_text(stmt, col, "\(param)", -1, nil)
            }
        }
    }
}
