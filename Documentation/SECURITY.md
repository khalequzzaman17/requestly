# Requestly Security Architecture

Requestly is designed as a local-first, privacy-focused native developer tool.

## 1. Local-First Data Storage
- No telemetry, third-party analytics, or background telemetry beacons.
- All requests, history, and collections remain strictly on the user's local machine.

## 2. Secrets & Credential Protection
- Sensitive tokens and passwords are never logged to stdout or system logs.
- Sensitive environment variables are marked as secrets (`isSecret = true`) and masked in the UI.
- Credential Sanitization (`CredentialSanitizer`):
  - Automatically redacts `Authorization`, `X-API-Key`, and authentication tokens when exporting requests, sharing diagnostics, or writing logs.
- macOS Keychain integration (`KeychainManager`):
  - Integrates with macOS `Security.framework` (`SecItemAdd`, `SecItemCopyMatching`, `SecItemUpdate`, `SecItemDelete`) for storing access tokens and sensitive environment values with hardware-backed encryption.

## 3. Network Security & TLS
- Native `URLSession` implementation leverages Apple's network stack.
- Configurable TLS validation: Users can disable SSL validation for local development (`localhost` / self-signed certs) while defaulting to strict system CA validation for external APIs.
- Safe response preview: The HTML preview disables script execution to prevent remote API responses from running untrusted JavaScript inside the app.

## 4. Code Signing & Apple Notarization
- Ad-hoc signature applied for local builds: `codesign --force --deep -s -`
- Developer ID distribution signing supported:
  ```bash
  codesign --deep --force --options runtime --sign "Developer ID Application: Your Name (TEAM_ID)" build/Requestly.app
  ```
- Notarization automated in `scripts/notarize.sh` using Apple's `notarytool`:
  ```bash
  xcrun notarytool submit build/Requestly-Universal.dmg --keychain-profile "PROFILE_NAME" --wait
  xcrun stapler staple build/Requestly-Universal.dmg
  ```
