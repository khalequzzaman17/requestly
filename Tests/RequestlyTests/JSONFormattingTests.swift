import Foundation
import RequestlyCore

public enum JSONFormattingTests {
    public static func runAll() async {
        print("\n📦 Running JSONFormattingTests...")
        
        await TestHarness.runTest("Pretty Print Standard JSON") {
            let input = "{\"name\":\"Requestly\",\"speed\":100,\"native\":true}"
            let result = JSONPrettyFormatter.shared.prettyPrint(string: input, indentSpaces: 2)
            switch result {
            case .success(let pretty):
                try TestHarness.assertTrue(pretty.contains("\"name\"") && pretty.contains("\"Requestly\""))
                try TestHarness.assertTrue(pretty.contains("\"native\"") && pretty.contains("true"))
                try TestHarness.assertTrue(pretty.contains("\"speed\"") && pretty.contains("100"))
                try TestHarness.assertTrue(pretty.contains("\n"))
            case .failure(let error):
                throw error
            }
        }
        
        await TestHarness.runTest("Pretty Print Nested Objects and Arrays") {
            let input = """
            {"success":true,"data":{"user":{"id":101,"name":"John Doe","active":true},"roles":["admin","developer"]}}
            """
            let result = JSONPrettyFormatter.shared.prettyPrint(string: input, indentSpaces: 2)
            switch result {
            case .success(let pretty):
                try TestHarness.assertTrue(pretty.contains("\"user\"") && pretty.contains("{"))
                try TestHarness.assertTrue(pretty.contains("\"roles\"") && pretty.contains("["))
                try TestHarness.assertTrue(pretty.contains("\"admin\""))
            case .failure(let error):
                throw error
            }
        }
        
        await TestHarness.runTest("Minify JSON to single line") {
            let input = """
            {
              "title": "API Tester",
              "stars": 5
            }
            """
            let result = JSONPrettyFormatter.shared.minify(string: input)
            switch result {
            case .success(let minified):
                try TestHarness.assertFalse(minified.contains("\n"))
                try TestHarness.assertTrue(minified.contains("\"stars\":5") || minified.contains("\"stars\": 5"))
            case .failure(let error):
                throw error
            }
        }
        
        await TestHarness.runTest("Detect and handle Invalid JSON safely") {
            let invalid = "{ not a valid json at all }"
            let result = JSONPrettyFormatter.shared.prettyPrint(string: invalid)
            switch result {
            case .success:
                throw TestError.assertionFailed("Should fail for invalid JSON")
            case .failure(let error):
                try TestHarness.assertNotNil(error.errorDescription)
            }
        }
        
        await TestHarness.runTest("JSON Tree Parser node hierarchy and types") {
            let input = """
            {
                "id": 123,
                "name": "Widget",
                "tags": ["alpha", "beta"],
                "metadata": {
                    "active": true,
                    "deleted": null
                }
            }
            """
            let root = try JSONTreeParser.shared.parse(string: input)
            try TestHarness.assertEqual(root.children.count, 4)
            
            let idNode = root.children.first(where: { $0.key == "id" })
            try TestHarness.assertNotNil(idNode)
            try TestHarness.assertEqual(idNode?.nodeType, .number("123"))
            
            let tagsNode = root.children.first(where: { $0.key == "tags" })
            try TestHarness.assertNotNil(tagsNode)
            try TestHarness.assertEqual(tagsNode?.children.count, 2)
            
            let metaNode = root.children.first(where: { $0.key == "metadata" })
            try TestHarness.assertNotNil(metaNode)
            let activeNode = metaNode?.children.first(where: { $0.key == "active" })
            try TestHarness.assertEqual(activeNode?.nodeType, .boolean(true))
            let nullNode = metaNode?.children.first(where: { $0.key == "deleted" })
            try TestHarness.assertEqual(nullNode?.nodeType, .null)
        }
    }
}
