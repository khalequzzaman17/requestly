# Requestly — Native macOS HTTP Request Tester & API Client

![Platform](https://img.shields.io/badge/Platform-macOS%2013%2B%20Ventura-black?style=flat-square&logo=apple)
![Architecture](https://img.shields.io/badge/Architecture-Universal%202%20(Apple%20Silicon%20%2B%20Intel)-5685F7?style=flat-square)
![Swift](https://img.shields.io/badge/Swift-5.9%2B%20%7C%20SwiftUI%20%7C%20AppKit-F05138?style=flat-square&logo=swift)
![License](https://img.shields.io/badge/License-MIT-36C98F?style=flat-square)
![Theme](https://img.shields.io/badge/Theme-Dark%20Mode%20Only-111318?style=flat-square)

**Requestly** is a fast, lightweight, distraction-free HTTP client and API testing application designed natively for macOS. It delivers the core capabilities of Postman and Insomnia while maintaining a sub-second startup time, negligible memory footprint (~20 MB vs 300 MB+ in Electron), local-first privacy, and an elegant macOS-tailored dark interface.

> Developed with ❤️ by **Khalequzzaman**

---

## ✨ Highlights

- **100% Native Architecture:** Engineered purely in Swift, SwiftUI, and AppKit with zero Electron, Chromium, or web-view overhead.
- **Strict Dark Mode Only:** Permanent, developer-focused dark interface (`#111318`) with dark scrollbars, custom method badges, and high-contrast typography.
- **Single-Instance Enforcement:** Automatic runtime lock ensures only one instance of Requestly ever runs concurrently, preventing duplicate windows and processes.
- **Universal 2 Binary:** Native fat binaries optimized for both Apple Silicon (`arm64`) and Intel (`x86_64`) Macs.
- **Smart Response Viewer:** Automatic JSON formatting and pretty-printing with collapsible tree hierarchy, search, raw view, headers inspector, and cookie viewer.
- **Defense-in-Depth Security:**
  - **Scheme Guard:** Strict protocol validation permitting only `http` and `https` schemes; blocks `file://`, `javascript:`, and protocol smuggling.
  - **Enforce HTTPS Only:** Optional policy to disallow unencrypted HTTP traffic (except `localhost` and `127.0.0.1` for local development).
  - **Hardened Runtime & Entitlements:** Signed with macOS Hardened Runtime, sandboxed file operations, and strict memory execution constraints.
  - **Hardware-Backed Keychain:** Passwords and tokens stored securely using Apple's `Security.framework` with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
  - **SQLite Secure Deletion:** Local database enables `PRAGMA secure_delete = ON` to zero out deleted records on disk.
  - **Automatic Credential Redaction:** Sensitive authorization headers and passwords are automatically masked before saving to history or copying cURL.
  - **DoS & OOM Protection:** Configurable maximum response payload cap (default 50 MB) and JSON nesting recursion depth guard (max 64 levels).
- **User-Agent Selector & Presets:** Categorized presets for Desktop Browsers (Chrome, Safari, Firefox, Edge), Mobile (iPhone, Android), Tablets (iPad, Galaxy Tab), and API clients (cURL, PostmanRuntime).
- **Multi-Environment Variables:** Live `{{variable}}` interpolation across URLs, headers, params, and body with sensitive value masking.
- **cURL & Postman Interoperability:** Instant import and export of cURL commands (with POSIX shell quote sanitization) and Postman Collection v2.1 archives.
- **Keyboard-First Navigation:** Optimized with standard macOS shortcuts (`⌘Enter`, `⌘N`, `⌘T`, `⌘W`, `⌘S`, `⌘K`, `⌥⌘C`, `⌘,`).

---

## 🏛 Architecture Overview

```
requestly/
├── Sources/
│   ├── RequestlyApp/             # App entry point, lifecycle, native menu commands
│   └── RequestlyCore/
│       ├── App/                  # App configuration, AppDelegate, notifications
│       ├── Core/
│       │   ├── Database/         # SQLite engine (WAL, migrations, secure_delete)
│       │   ├── ImportExport/     # cURL parser/exporter, Postman & Requestly archives
│       │   ├── Networking/       # URLSession engine, User-Agent presets, multipart builder
│       │   ├── Security/         # macOS Keychain manager & credential sanitizers
│       │   └── Utilities/        # JSON pretty-printer, tree parser, validators
│       ├── DesignSystem/         # Dark palette, typography, button styles, method colors
│       ├── Domain/               # Models (HTTPRequest, Response, Collections), Use Cases
│       └── Features/
│           ├── Environments/     # Multi-environment variable manager
│           ├── ImportExport/     # Import modal dialogs
│           ├── RequestEditor/    # URL bar, params, headers, auth, body editor
│           ├── ResponseViewer/   # Pretty JSON, raw viewer, headers, cookies
│           ├── Settings/         # General, network, security, storage, shortcuts, about
│           ├── Sidebar/          # Collections, nested folders, history, search
│           └── Workspace/        # Tab manager, split view, command palette
├── Resources/                    # Info.plist, AppIcon.icns, Requestly.entitlements
├── Tests/                        # Comprehensive test runner & 28 unit/integration tests
└── scripts/                      # Build, packaging, testing, and notarization scripts
```

---

## 🚀 Getting Started

### Prerequisites
- macOS 13.0 Ventura or later
- Xcode 15+ or Command Line Tools with Swift 5.9+

### 1. Running the Automated Test Suite
Run the 28 comprehensive unit and integration tests covering JSON parsing, SQLite CRUD, cURL shell quoting, variable resolution, and security defenses:

```bash
./scripts/test.sh
```

### 2. Building for Native Host Architecture
Compile and assemble `build/Requestly.app` optimized for your current machine:

```bash
./scripts/build.sh
```

### 3. Building Universal 2 Binary (Apple Silicon + Intel)
Generate a dual-architecture Universal 2 bundle signed with Hardened Runtime and App Entitlements:

```bash
./scripts/build-universal.sh
```

Output: `build/Requestly.app`

### 4. Packaging the Distributable DMG
Package the Universal application into a compressed `.dmg` disk image with an `/Applications` drag-and-drop installer symlink:

```bash
./scripts/package-dmg.sh
```

Output: `build/Requestly-Universal.dmg` (~3.6 MB)

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action | Scope |
|:---|:---|:---|
| **⌘ + Enter** | Send / Execute active HTTP request | Global |
| **⌘ + .** | Cancel active in-flight request | Global |
| **⌘ + N** | New Request Tab | Global |
| **⌘ + T** | New Tab | Global |
| **⌘ + W** | Close active Tab | Global |
| **⌘ + S** | Save request to Collection | Global |
| **⌥ + ⌘ + C** | Copy request as cURL command | Global |
| **⌘ + K** | Quick Command Palette / Search | Global |
| **⌘ + ,** | Open Settings Modal | Global |

---

## 🌐 HTTP Networking Engine

- **Supported Methods:** `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `HEAD`, `OPTIONS`
- **Request Body Formats:**
  - `None`
  - `JSON` (syntax validated with indentation options)
  - `Text` (`text/plain; charset=utf-8`)
  - `Form Data` (multipart key-value and file uploads with size and type safety)
  - `x-www-form-urlencoded`
  - `Binary File`
- **Authentication Handlers:**
  - `No Auth`
  - `Bearer Token`
  - `Basic Auth` (Username & Password)
  - `API Key` (Header or Query Parameter)
  - `OAuth 2.0 Token`
- **Engine Controls:** Configurable request timeouts (1s–300s), automatic redirect following with downgrade prevention, SSL certificate validation toggle, and custom User-Agent override.

---

## 🔒 Security & Privacy Model

Requestly is designed with strict **local-first** security principles:

1. **Zero Telemetry:** No tracking, no background analytics, no third-party network pings.
2. **Keychain Protection:** Sensitive secrets are stored in the macOS Keychain tagged with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
3. **Command Injection Defense:** The cURL exporter applies strict POSIX shell quoting to every parameter to prevent shell break-outs.
4. **History Redaction:** Authorization tokens and credentials are masked before writing request snapshots to the local database.
5. **Secure Database Deletion:** SQLite uses `PRAGMA secure_delete = ON` to ensure deleted requests and history cannot be recovered from unallocated disk space.
6. **Hardened Runtime:** Compiled and signed with Apple's Hardened Runtime and entitlements (`com.apple.security.network.client`, `com.apple.security.files.user-selected.read-write`).

---

## 🚢 Code Signing & Notarization

To sign with your Apple Developer ID and submit for Apple Gatekeeper notarization:

```bash
export APPLE_ID="developer@example.com"
export TEAM_ID="YOUR_TEAM_ID"
export APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"

./scripts/notarize.sh
```

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

Copyright © 2026 **Khalequzzaman**. All rights reserved.
