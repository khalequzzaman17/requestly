import Foundation
import RequestlyCore

public enum NetworkingTests {
    public static func runAll() async {
        print("\n📦 Running NetworkingTests...")
        
        await TestHarness.runTest("HTTPMethod properties and bodies") {
            try TestHarness.assertTrue(HTTPMethod.post.hasBody)
            try TestHarness.assertTrue(HTTPMethod.put.hasBody)
            try TestHarness.assertTrue(HTTPMethod.patch.hasBody)
            try TestHarness.assertTrue(HTTPMethod.delete.hasBody)
            try TestHarness.assertFalse(HTTPMethod.get.hasBody)
            try TestHarness.assertFalse(HTTPMethod.head.hasBody)
            try TestHarness.assertFalse(HTTPMethod.options.hasBody)
        }
        
        await TestHarness.runTest("Multipart Form Data Builder creates boundary and payload") {
            let builder = MultipartFormDataBuilder(boundary: "TestBoundary123")
            builder.addField(name: "username", value: "alice")
            builder.addField(name: "email", value: "alice@example.com")
            let data = builder.finalize()
            let str = String(data: data, encoding: .utf8) ?? ""
            
            try TestHarness.assertTrue(str.contains("--TestBoundary123"))
            try TestHarness.assertTrue(str.contains("name=\"username\""))
            try TestHarness.assertTrue(str.contains("alice"))
            try TestHarness.assertTrue(str.contains("--TestBoundary123--"))
        }
        
        await TestHarness.runTest("URL Validator extracts and updates Query Parameters accurately") {
            let initial = "https://api.example.com/search?q=swift&sort=desc"
            let params = URLValidator.extractQueryParams(from: initial)
            try TestHarness.assertEqual(params.count, 2)
            try TestHarness.assertEqual(params[0].key, "q")
            try TestHarness.assertEqual(params[0].value, "swift")
            try TestHarness.assertEqual(params[1].key, "sort")
            try TestHarness.assertEqual(params[1].value, "desc")
            
            let updatedParams = [
                KeyValueItem(key: "q", value: "macos"),
                KeyValueItem(key: "page", value: "2")
            ]
            let updatedURL = URLValidator.updateURL("https://api.example.com/search", withQueryParams: updatedParams)
            try TestHarness.assertTrue(updatedURL.contains("q=macos"))
            try TestHarness.assertTrue(updatedURL.contains("page=2"))
        }
        
        await TestHarness.runTest("HTTPResponseModel JSON and Status helpers") {
            let jsonBody = "{\"status\": \"ok\", \"count\": 42}".data(using: .utf8)!
            let response = HTTPResponseModel(
                statusCode: 200,
                statusDescription: "OK",
                headers: ["Content-Type": "application/json; charset=utf-8"],
                bodyData: jsonBody
            )
            
            try TestHarness.assertTrue(response.isSuccess)
            try TestHarness.assertTrue(response.isJSON)
            try TestHarness.assertFalse(response.isHTML)
            try TestHarness.assertFalse(response.isImage)
            try TestHarness.assertEqual(response.rawBodyString, "{\"status\": \"ok\", \"count\": 42}")
        }
        
        await TestHarness.runTest("HTTPResponseModel Fallback JSON detection without Content-Type") {
            let jsonBody = "[1, 2, 3, 4]".data(using: .utf8)!
            let response = HTTPResponseModel(
                statusCode: 200,
                headers: ["Content-Type": "text/plain"],
                bodyData: jsonBody
            )
            // Even though Content-Type is text/plain, fallback detects it is valid JSON array!
            try TestHarness.assertTrue(response.isJSON)
        }
    }
}

