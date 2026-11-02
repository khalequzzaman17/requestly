import Foundation
import RequestlyCore

public enum ImportExportTests {
    public static func runAll() async {
        print("\n📦 Running ImportExportTests...")
        
        await TestHarness.runTest("cURL Parser Basic GET with Headers") {
            let curl = "curl -X GET 'https://api.example.com/items?limit=10' -H 'Accept: application/json'"
            let req = try CurlParserAndExporter.shared.parse(curlCommand: curl)
            try TestHarness.assertEqual(req.method, .get)
            try TestHarness.assertEqual(req.url, "https://api.example.com/items?limit=10")
            try TestHarness.assertEqual(req.headers.first(where: { $0.key == "Accept" })?.value, "application/json")
            try TestHarness.assertEqual(req.queryParams.first(where: { $0.key == "limit" })?.value, "10")
        }
        
        await TestHarness.runTest("cURL Parser with Bearer Auth and JSON Body") {
            let curl = """
            curl -X POST 'https://api.example.com/login' \\
              -H 'Content-Type: application/json' \\
              -H 'Authorization: Bearer my_secret_token' \\
              -d '{"email":"test@example.com","password":"secret"}'
            """
            let req = try CurlParserAndExporter.shared.parse(curlCommand: curl)
            try TestHarness.assertEqual(req.method, .post)
            try TestHarness.assertEqual(req.auth.type, .bearer)
            try TestHarness.assertEqual(req.auth.bearerToken, "my_secret_token")
            try TestHarness.assertEqual(req.bodyType, .json)
            try TestHarness.assertTrue(req.rawBodyText.contains("test@example.com"))
        }
        
        await TestHarness.runTest("cURL Exporter generates valid curl command") {
            let req = HTTPRequestModel(
                name: "Create User",
                method: .post,
                url: "https://api.example.com/users",
                queryParams: [KeyValueItem(key: "role", value: "admin")],
                headers: [KeyValueItem(key: "Accept", value: "application/json")],
                bodyType: .json,
                rawBodyText: "{\"name\":\"Alice\"}",
                auth: AuthConfig(type: .bearer, bearerToken: "test_token")
            )
            
            let curl = CurlParserAndExporter.shared.export(request: req)
            try TestHarness.assertTrue(curl.contains("curl"))
            try TestHarness.assertTrue(curl.contains("-X POST"))
            try TestHarness.assertTrue(curl.contains("'https://api.example.com/users?role=admin'"))
            try TestHarness.assertTrue(curl.contains("-H 'Authorization: Bearer test_token'"))
            try TestHarness.assertTrue(curl.contains("-d '{\"name\":\"Alice\"}'"))
        }
        
        await TestHarness.runTest("Postman Collection v2.1 Import Parser") {
            let postmanJSON = """
            {
              "info": {
                "name": "Sample Postman Collection",
                "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
              },
              "item": [
                {
                  "name": "Auth",
                  "item": [
                    {
                      "name": "Login",
                      "request": {
                        "method": "POST",
                        "header": [
                          { "key": "Content-Type", "value": "application/json" }
                        ],
                        "body": {
                          "mode": "raw",
                          "raw": "{\\"user\\": \\"admin\\"}"
                        },
                        "url": {
                          "raw": "https://api.example.com/auth/login"
                        }
                      }
                    }
                  ]
                }
              ]
            }
            """.data(using: .utf8)!
            
            let result = try PostmanCollectionParser.shared.parse(data: postmanJSON)
            try TestHarness.assertEqual(result.collection.name, "Sample Postman Collection")
            try TestHarness.assertEqual(result.folders.count, 1)
            try TestHarness.assertEqual(result.folders.first?.name, "Auth")
            try TestHarness.assertEqual(result.requests.count, 1)
            try TestHarness.assertEqual(result.requests.first?.request.name, "Login")
            try TestHarness.assertEqual(result.requests.first?.request.method, .post)
            try TestHarness.assertEqual(result.requests.first?.request.url, "https://api.example.com/auth/login")
        }
        
        await TestHarness.runTest("Requestly Collection Archive Export and Import") {
            let coll = CollectionModel(name: "Native Coll")
            let folder = FolderModel(collectionId: coll.id, name: "Folder 1")
            let req = HTTPRequestModel(name: "Request 1")
            let saved = SavedRequestModel(collectionId: coll.id, folderId: folder.id, request: req)
            
            let data = try RequestlyCollectionExportImport.shared.export(collection: coll, folders: [folder], requests: [saved])
            let restored = try RequestlyCollectionExportImport.shared.parse(data: data)
            
            try TestHarness.assertEqual(restored.collection.name, "Native Coll")
            try TestHarness.assertEqual(restored.folders.count, 1)
            try TestHarness.assertEqual(restored.requests.count, 1)
            try TestHarness.assertEqual(restored.requests.first?.request.name, "Request 1")
        }
    }
}
