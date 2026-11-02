import Foundation
import RequestlyCore

public enum SecurityAndVariableTests {
    public static func runAll() async {
        print("\n📦 Running SecurityAndVariableTests...")
        
        await TestHarness.runTest("Credential Sanitization of Sensitive Headers") {
            let headers = [
                KeyValueItem(key: "Authorization", value: "Bearer secret_123"),
                KeyValueItem(key: "X-Api-Key", value: "secret_api_key_abc"),
                KeyValueItem(key: "Accept", value: "application/json")
            ]
            
            let sanitized = CredentialSanitizer.sanitize(headers: headers)
            try TestHarness.assertEqual(sanitized.first(where: { $0.key == "Authorization" })?.value, "••••••••")
            try TestHarness.assertEqual(sanitized.first(where: { $0.key == "X-Api-Key" })?.value, "••••••••")
            try TestHarness.assertEqual(sanitized.first(where: { $0.key == "Accept" })?.value, "application/json")
        }
        
        await TestHarness.runTest("Request Credential Redaction") {
            let req = HTTPRequestModel(
                auth: AuthConfig(type: .basic, basicUsername: "admin", basicPassword: "SuperSecretPassword123!")
            )
            let sanitized = CredentialSanitizer.sanitize(request: req)
            try TestHarness.assertEqual(sanitized.auth.basicPassword, "••••••••")
        }
        
        await TestHarness.runTest("Environment Variable Substitution in URL and Headers") {
            let env = EnvironmentModel(
                name: "Dev",
                variables: [
                    EnvironmentVariable(key: "base_url", value: "https://api.dev.local"),
                    EnvironmentVariable(key: "version", value: "v2"),
                    EnvironmentVariable(key: "token", value: "tok_999")
                ]
            )
            
            let resolver = VariableResolutionUseCase.shared
            let url = "{{base_url}}/{{version}}/users"
            let resolved = resolver.resolve(text: url, in: env)
            try TestHarness.assertEqual(resolved, "https://api.dev.local/v2/users")
            
            let headerText = "Bearer {{token}}"
            let resolvedHeader = resolver.resolve(text: headerText, in: env)
            try TestHarness.assertEqual(resolvedHeader, "Bearer tok_999")
        }
        
        await TestHarness.runTest("Unresolved Variables Detection") {
            let env = EnvironmentModel(
                name: "Dev",
                variables: [
                    EnvironmentVariable(key: "known_var", value: "123")
                ]
            )
            
            let resolver = VariableResolutionUseCase.shared
            let text = "{{known_var}} and {{missing_var_1}} plus {{missing_var_2}}"
            let unresolved = resolver.findUnresolvedVariables(in: text, environment: env)
            
            try TestHarness.assertEqual(unresolved.count, 2)
            try TestHarness.assertTrue(unresolved.contains("missing_var_1"))
            try TestHarness.assertTrue(unresolved.contains("missing_var_2"))
            try TestHarness.assertFalse(unresolved.contains("known_var"))
        }
        
        await TestHarness.runTest("Insecure URL Schemes Blocked by NetworkEngine") {
            let engine = NetworkEngine.shared
            
            do {
                _ = try await engine.execute(request: HTTPRequestModel(url: "file:///etc/passwd"))
                try TestHarness.assertTrue(false, "Expected error for file:// scheme")
            } catch let error as NetworkError {
                switch error {
                case .insecureSchemeBlocked:
                    try TestHarness.assertTrue(true)
                default:
                    try TestHarness.assertTrue(false, "Expected insecureSchemeBlocked but got \(error)")
                }
            } catch {
                try TestHarness.assertTrue(false, "Unexpected error: \(error)")
            }
        }
        
        await TestHarness.runTest("cURL Command Injection Prevention via Shell Quoting") {
            let maliciousUrl = "https://example.com/api?q=test'; rm -rf /; echo '"
            let maliciousHeader = "evil'; id; '"
            let req = HTTPRequestModel(
                url: maliciousUrl,
                headers: [KeyValueItem(key: "X-Exploit", value: maliciousHeader, isEnabled: true)],
                auth: AuthConfig(type: .bearer, bearerToken: "token'; whoami; '")
            )
            
            let curl = CurlParserAndExporter.shared.export(request: req)
            // Verify single quotes are escaped properly as '\'' so bash cannot break out
            try TestHarness.assertTrue(curl.contains("'\\''"))
            try TestHarness.assertTrue(!curl.contains("test'; rm -rf /; echo '"))
        }
        
        await TestHarness.runTest("cURL Secret Redaction on Demand") {
            let req = HTTPRequestModel(
                url: "https://api.example.com/v1",
                headers: [
                    KeyValueItem(key: "Authorization", value: "Bearer secret_prod_key_999", isEnabled: true),
                    KeyValueItem(key: "X-Api-Key", value: "live_secret_456", isEnabled: true)
                ]
            )
            
            let safeCurl = CurlParserAndExporter.shared.export(request: req, sanitizeSecrets: true)
            try TestHarness.assertTrue(safeCurl.contains("••••••••"))
            try TestHarness.assertFalse(safeCurl.contains("secret_prod_key_999"))
            try TestHarness.assertFalse(safeCurl.contains("live_secret_456"))
        }
        
        await TestHarness.runTest("JSON Tree Parser Recursion Depth Safety Guard") {
            // Build deeply nested JSON: {"a":{"a":{"a": ... }}}
            var nested = "{\"val\": 1}"
            for _ in 0..<80 {
                nested = "{\"wrap\": \(nested)}"
            }
            
            let root = try JSONTreeParser.shared.parse(string: nested)
            try TestHarness.assertEqual(root.depth, 0)
            // Traversing down must encounter the depth guard without crashing the thread
            var current = root
            var reachedGuard = false
            while let firstChild = current.children.first {
                current = firstChild
                if case .string(let str) = current.nodeType, str.contains("Nesting depth exceeded") {
                    reachedGuard = true
                    break
                }
            }
            try TestHarness.assertTrue(reachedGuard, "Expected depth safety guard to halt recursion")
        }
    }
}
