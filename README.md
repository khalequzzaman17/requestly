# Requestly — Native macOS HTTP Request Tester & API Client

Requestly is a fast, lightweight, elegant HTTP client and API testing application designed for macOS. It offers the essential capabilities of Postman and Insomnia while maintaining a simpler interface, lower resource consumption (2 MB vs 200 MB+), instant startup, and a genuinely native macOS experience.

---

## Highlights

- **Native Swift, SwiftUI & AppKit**: Zero Electron, Chromium, or web-view overhead.
- **Strict Dark Mode Only**: Engineered with a permanent, distraction-free developer dark theme (`#111318`).
- **Universal 2 Binary**: Full native execution on Apple Silicon (`arm64`) and Intel (`x86_64`) Macs.
- **Smart JSON Inspector**: Automatically formats and pretty-prints valid JSON responses by default, featuring a collapsible tree view with syntax highlighting, search, line numbers, and copy/download controls.
- **Persistent Local Database**: Uses normalized SQLite with WAL mode, migrations, foreign key cascading, and zero data leakage.
- **Multi-Environment Support**: Define variables (`{{base_url}}`, `{{token}}`) with secret masking and live substitution.
- **cURL & Postman Interoperability**: Instant one-click import and export of cURL commands and Postman Collection v2.1 archives.
- **macOS Keychain Integration**: Hardware-encrypted credential storage via Apple's `Security.framework`.
- **Keyboard-First Design**: Optimized with standard macOS shortcuts (`⌘Enter`, `⌘N`, `⌘T`, `⌘K`, `⌘S`, `⌥⌘C`).

---

## Architecture Overview

```
Requestly/
├── App/                # Application entry point, window config, dark mode enforcer
├── DesignSystem/       # Dark theme palette, method badges, typography, UI components
├── Domain/             # HTTP models, request/response models, protocols, use cases
├── Core/               # URLSession network engine, SQLite database, Keychain, parsers
├── Features/           # Workspace, Sidebar, RequestEditor, ResponseViewer, Settings
├── Tests/              # Comprehensive test runner & unit/integration test suites
└── scripts/            # Build, universal packaging, test, and notarization scripts
```

---

## Getting Started

### Prerequisites
- macOS 13.0 Ventura or later
- Command Line Tools with Swift 5.9+ / Swift 6

### Running Automated Tests
Run the comprehensive test suite (JSON pretty printing, database CRUD, import/export, variable resolution, and networking):

```bash
./scripts/test.sh
```

### Building the Native macOS App

To build `build/Requestly.app` for your host architecture:

```bash
./scripts/build.sh
```

### Building the Universal 2 Binary (arm64 + x86_64)

To build a universal macOS application supporting both Apple Silicon and Intel:

```bash
./scripts/build-universal.sh
```

### Packaging into a Distributable DMG

To package the Universal application into a compressed, distributable `.dmg` with an `/Applications` installer shortcut:

```bash
./scripts/package-dmg.sh
```

The resulting DMG will be output to: `build/Requestly-Universal.dmg` (~2.1 MB).

---

## Keyboard Shortcuts

| Shortcut | Action |
|:---|:---|
| **⌘ Enter** | Send / Execute current HTTP request |
| **⌘ N** | New Request |
| **⌘ T** | New Request Tab |
| **⌘ W** | Close current tab |
| **⌘ S** | Save request to collection |
| **⌘ K** | Command Palette / Quick Search |
| **⌥ ⌘ C** | Copy request as cURL command |
| **⌘ F** | Search response body / headers |

---

## HTTP Engine Capabilities

- **Methods**: `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `HEAD`, `OPTIONS`
- **Body Formats**: `None`, `JSON`, `Text`, `Form Data` (with file upload), `x-www-form-urlencoded`, `Binary file`
- **Authentication**: `No Auth`, `Bearer Token`, `Basic Auth`, `API Key` (Header or Query Param), `OAuth 2.0`
- **Features**: Async/await concurrency, in-flight request cancellation, configurable timeouts, custom user agents, redirect controls, and SSL validation toggles.

---

## Code Signing & Apple Notarization

To notarize your build for macOS Gatekeeper:

```bash
export APPLE_ID="developer@example.com"
export TEAM_ID="YOUR_TEAM_ID"
export APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"
./scripts/notarize.sh
```

---

## License

Copyright © 2026 Requestly. All rights reserved.
