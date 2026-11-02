# Requestly Database Schema & Migrations

Requestly uses a local SQLite database (`SQLite3`) embedded directly into macOS.
The database file is stored in:
`~/Library/Application Support/Requestly/requestly.sqlite`

## 1. Schema Tables

### `schema_migrations`
Tracks database migration versions applied over time.
- `version`: INTEGER PRIMARY KEY
- `applied_at`: REAL NOT NULL (Unix timestamp)

### `collections`
Top-level workspaces and request groups.
- `id`: TEXT PRIMARY KEY (UUID)
- `name`: TEXT NOT NULL
- `description`: TEXT NOT NULL DEFAULT ''
- `order_index`: INTEGER NOT NULL DEFAULT 0
- `created_at`: REAL NOT NULL
- `updated_at`: REAL NOT NULL

### `folders`
Hierarchical folders supporting arbitrary nesting.
- `id`: TEXT PRIMARY KEY (UUID)
- `collection_id`: TEXT NOT NULL (FK -> collections(id) ON DELETE CASCADE)
- `parent_folder_id`: TEXT (FK -> folders(id) ON DELETE CASCADE)
- `name`: TEXT NOT NULL
- `description`: TEXT NOT NULL DEFAULT ''
- `order_index`: INTEGER NOT NULL DEFAULT 0
- `created_at`: REAL NOT NULL
- `updated_at`: REAL NOT NULL

### `saved_requests`
Saved HTTP requests within collections and folders.
- `id`: TEXT PRIMARY KEY (UUID)
- `collection_id`: TEXT NOT NULL (FK -> collections(id) ON DELETE CASCADE)
- `folder_id`: TEXT (FK -> folders(id) ON DELETE CASCADE)
- `name`: TEXT NOT NULL
- `request_json`: TEXT NOT NULL (Serialized HTTPRequestModel)
- `created_at`: REAL NOT NULL
- `updated_at`: REAL NOT NULL

### `environments`
Environment configurations (Development, Staging, Production, etc.).
- `id`: TEXT PRIMARY KEY (UUID)
- `name`: TEXT NOT NULL
- `is_selected`: INTEGER NOT NULL DEFAULT 0
- `created_at`: REAL NOT NULL
- `updated_at`: REAL NOT NULL

### `environment_variables`
Key-value variables belonging to an environment.
- `id`: TEXT PRIMARY KEY (UUID)
- `environment_id`: TEXT NOT NULL (FK -> environments(id) ON DELETE CASCADE)
- `key`: TEXT NOT NULL
- `value`: TEXT NOT NULL
- `is_secret`: INTEGER NOT NULL DEFAULT 0
- `is_enabled`: INTEGER NOT NULL DEFAULT 1

### `request_history`
Audit log of executed HTTP requests.
- `id`: TEXT PRIMARY KEY (UUID)
- `request_name`: TEXT NOT NULL
- `method`: TEXT NOT NULL (GET, POST, etc.)
- `url`: TEXT NOT NULL
- `status_code`: INTEGER NOT NULL
- `status_description`: TEXT NOT NULL
- `duration_ms`: REAL NOT NULL
- `byte_count`: INTEGER NOT NULL
- `timestamp`: REAL NOT NULL (Indexed DESC)
- `request_snapshot`: TEXT NOT NULL

### `application_settings`
Global application settings.
- `key`: TEXT PRIMARY KEY
- `value`: TEXT NOT NULL (Serialized JSON)

## 2. Integrity and Concurrency
- `PRAGMA foreign_keys = ON;` is enforced on every connection.
- `PRAGMA journal_mode = WAL;` (Write-Ahead Logging) enables high concurrency and resilient crash recovery.
- All multi-statement write operations run inside explicit `BEGIN TRANSACTION` / `COMMIT` / `ROLLBACK` blocks.
