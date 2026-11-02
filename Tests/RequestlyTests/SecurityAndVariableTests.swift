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
    }
}
