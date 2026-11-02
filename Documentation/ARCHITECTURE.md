# Requestly Architecture Documentation

## 1. Overview
Requestly is a native macOS HTTP client and API testing application designed for developers. It is built strictly using **Swift**, **SwiftUI**, and **AppKit** with zero Electron, Chromium, or web-view UI overhead.

## 2. Layered Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       Presentation Layer                    │
│   (SwiftUI + AppKit Native Views, Strict Dark Mode System)  │
│                                                             │
│   - WorkspaceView          - SidebarView                    │
│   - RequestEditorView      - ResponseViewerView             │
│   - EnvironmentManagerView - CommandPaletteView (⌘K)        │
└──────────────────────────────┬──────────────────────────────┘
                               │ ObservableObject Bindings
┌──────────────────────────────▼──────────────────────────────┐
│                    ViewModel / State Layer                  │
│                                                             │
│   - WorkspaceViewModel     - SidebarViewModel               │
│   - RequestEditorViewModel - ResponseViewerViewModel        │
│   - EnvironmentViewModel   - SettingsViewModel              │
└──────────────────────────────┬──────────────────────────────┘
                               │ Clean Domain Interactions
┌──────────────────────────────▼──────────────────────────────┐
│                        Domain Layer                         │
│                                                             │
│   - Models: HTTPRequest, HTTPResponse, Collection, Env      │
│   - UseCases: ExecuteRequest, VariableResolution, CurlExport│
│   - Protocols: NetworkService, DatabaseService, Keychain    │
└──────────────────────────────┬──────────────────────────────┘
                               │ Concrete Implementations
┌──────────────────────────────▼──────────────────────────────┐
│                     Core Infrastructure                     │
│                                                             │
│   - NetworkEngine (URLSession, Async/Await Concurrency)     │
│   - SQLiteDatabase (Native SQLite3, Migrations, WAL Mode)   │
│   - KeychainManager (Security.framework SecItem*)           │
│   - ImportExport (cURL Parser/Exporter, Postman v2.1)       │
│   - JSONFormatter & JSONTreeParser (Collapsible Native Tree)│
└─────────────────────────────────────────────────────────────┘
```

## 3. Strict Dark-Mode System
The application is enforced into macOS dark appearance regardless of the system appearance setting:
- Programmatic enforcement in `AppDelegate`: `NSApp.appearance = NSAppearance(named: .darkAqua)`
- Window background customization: `#111318`
- Dark palette constants across all components:
  - Main background: `#111318`
  - Sidebar: `#171A21`
  - Editor: `#151820`
  - Secondary: `#1D222C`
  - Elevated: `#222733`
  - Accent: Primary blue `#5685F7`, Green `#36C98F`, Yellow `#E9B75C`, Red `#F07178`, Purple `#A855F7`
  - Borders: `#2A303B` / `#242A34`

## 4. Networking Engine & Concurrency
- Uses Swift's native modern concurrency (`async/await`) on `URLSession`.
- Requests run off the main thread with zero UI freezing.
- Requests support cancellation through active `URLSessionTask` handle mapping.
- Responses preserve raw unmutated byte data (`Data`) alongside parsed headers and cookies.

## 5. JSON Parsing & Pretty-Printing Engine
- Detects JSON via Content-Type (`application/json`, `application/*+json`, `application/problem+json`) with fallback heuristic analysis for servers returning plain-text JSON.
- Pretty is the default tab for valid JSON.
- Formats with 2 spaces by default.
- Collapsible tree view (`JSONTreeNode`) provides deep object/array folding, type badges, line numbers, search filtering, and copy/download controls.

