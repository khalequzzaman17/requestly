import Foundation
import RequestlyCore

public enum DatabaseTests {
    public static func runAll() async {
        print("\n📦 Running DatabaseTests...")
        
        await TestHarness.runTest("Collections CRUD and Persistence") {
            let tempDir = FileManager.default.temporaryDirectory
            let dbPath = tempDir.appendingPathComponent("test_coll_\(UUID().uuidString).sqlite").path
            defer { try? FileManager.default.removeItem(atPath: dbPath) }
            
            let dbService = try DatabaseService(path: dbPath)
            let coll = CollectionModel(name: "Test API Collection", description: "Integration test")
            try dbService.saveCollection(coll)
            
            var fetched = try dbService.fetchCollections()
            try TestHarness.assertEqual(fetched.count, 1)
            try TestHarness.assertEqual(fetched.first?.name, "Test API Collection")
            
            // Update
            var updated = coll
            updated.name = "Updated Collection"
            try dbService.saveCollection(updated)
            fetched = try dbService.fetchCollections()
            try TestHarness.assertEqual(fetched.first?.name, "Updated Collection")
            
            // Delete
            try dbService.deleteCollection(id: coll.id)
            fetched = try dbService.fetchCollections()
            try TestHarness.assertEqual(fetched.count, 0)
        }
        
        await TestHarness.runTest("Folders and Nested Hierarchy") {
            let tempDir = FileManager.default.temporaryDirectory
            let dbPath = tempDir.appendingPathComponent("test_folder_\(UUID().uuidString).sqlite").path
            defer { try? FileManager.default.removeItem(atPath: dbPath) }
            
            let dbService = try DatabaseService(path: dbPath)
            let coll = CollectionModel(name: "API Suite")
            try dbService.saveCollection(coll)
            
            let rootFolder = FolderModel(collectionId: coll.id, name: "Auth Endpoints")
            try dbService.saveFolder(rootFolder)
            
            let subFolder = FolderModel(collectionId: coll.id, parentFolderId: rootFolder.id, name: "OAuth")
            try dbService.saveFolder(subFolder)
            
            let folders = try dbService.fetchFolders(collectionId: coll.id)
            try TestHarness.assertEqual(folders.count, 2)
            try TestHarness.assertTrue(folders.contains(where: { $0.name == "Auth Endpoints" }))
            try TestHarness.assertTrue(folders.contains(where: { $0.name == "OAuth" && $0.parentFolderId == rootFolder.id }))
        }
        
        await TestHarness.runTest("Saved Requests Persistence") {
            let tempDir = FileManager.default.temporaryDirectory
            let dbPath = tempDir.appendingPathComponent("test_req_\(UUID().uuidString).sqlite").path
            defer { try? FileManager.default.removeItem(atPath: dbPath) }
            
            let dbService = try DatabaseService(path: dbPath)
            let coll = CollectionModel(name: "Requests Coll")
            try dbService.saveCollection(coll)
            
            let req = HTTPRequestModel(name: "Get User Profile", method: .get, url: "https://api.example.com/user")
            let saved = SavedRequestModel(collectionId: coll.id, request: req)
            try dbService.saveRequest(saved)
            
            let fetched = try dbService.fetchSavedRequests(collectionId: coll.id, folderId: nil)
            try TestHarness.assertEqual(fetched.count, 1)
            try TestHarness.assertEqual(fetched.first?.request.name, "Get User Profile")
            try TestHarness.assertEqual(fetched.first?.request.url, "https://api.example.com/user")
        }
        
        await TestHarness.runTest("Environments and Variables Persistence") {
            let tempDir = FileManager.default.temporaryDirectory
            let dbPath = tempDir.appendingPathComponent("test_env_\(UUID().uuidString).sqlite").path
            defer { try? FileManager.default.removeItem(atPath: dbPath) }
            
            let dbService = try DatabaseService(path: dbPath)
            let env = EnvironmentModel(
                name: "Staging",
                variables: [
                    EnvironmentVariable(key: "host", value: "staging.api.com"),
                    EnvironmentVariable(key: "token", value: "secret123", isSecret: true)
                ]
            )
            try dbService.saveEnvironment(env)
            
            let fetched = try dbService.fetchEnvironments()
            try TestHarness.assertEqual(fetched.count, 1)
            try TestHarness.assertEqual(fetched.first?.name, "Staging")
            try TestHarness.assertEqual(fetched.first?.variables.count, 2)
            try TestHarness.assertEqual(fetched.first?.variables.first(where: { $0.key == "token" })?.isSecret, true)
        }
        
        await TestHarness.runTest("Request History Tracking and Clearing") {
            let tempDir = FileManager.default.temporaryDirectory
            let dbPath = tempDir.appendingPathComponent("test_hist_\(UUID().uuidString).sqlite").path
            defer { try? FileManager.default.removeItem(atPath: dbPath) }
            
            let dbService = try DatabaseService(path: dbPath)
            let req = HTTPRequestModel(name: "Test Request", method: .post, url: "https://httpbin.org/post")
            let item = RequestHistoryItem(
                requestName: "Test Request",
                method: .post,
                url: "https://httpbin.org/post",
                statusCode: 200,
                statusDescription: "OK",
                durationMs: 145.2,
                byteCount: 850,
                requestSnapshot: req
            )
            try dbService.addHistoryItem(item)
            
            var history = try dbService.fetchHistory(limit: 50)
            try TestHarness.assertEqual(history.count, 1)
            try TestHarness.assertEqual(history.first?.statusCode, 200)
            
            try dbService.clearHistory()
            history = try dbService.fetchHistory(limit: 50)
            try TestHarness.assertEqual(history.count, 0)
        }
    }
}
