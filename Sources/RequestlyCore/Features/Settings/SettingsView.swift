import SwiftUI

public enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case network = "Network"
    case security = "Security"
    case editor = "Editor"
    case response = "Response"
    case storage = "Storage"
    case shortcuts = "Shortcuts"
    case about = "About"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .general: return "gearshape"
        case .network: return "network"
        case .security: return "lock.shield"
        case .editor: return "pencil"
        case .response: return "arrow.down.doc"
        case .storage: return "cylinder.split.1x2"
        case .shortcuts: return "command"
        case .about: return "info.circle"
        }
    }
}

public final class SettingsViewModel: ObservableObject {
    @Published public var selectedSection: SettingsSection = .general
    @Published public var settings = AppSettingsModel()
    @Published public var showClearConfirmDialog: Bool = false
    @Published public var showClearSuccessMessage: Bool = false
    
    public init() {
        if let loaded = try? DatabaseService.shared.loadSettings() {
            self.settings = loaded
        }
    }
    
    public func save() {
        try? DatabaseService.shared.saveSettings(settings)
    }
    
    public func clearHistory() {
        try? DatabaseService.shared.clearHistory()
        NotificationCenter.default.post(name: .historyCleared, object: nil)
        showClearSuccessMessage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.showClearSuccessMessage = false
        }
    }
}

public struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(AppTypography.headline)
                    .foregroundColor(DarkTheme.textPrimary)
                Spacer()
                Button(action: {
                    viewModel.save()
                    dismiss()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                        Text("Done")
                            .font(AppTypography.captionMedium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(DarkTheme.primaryBlue)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .focusable(false)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(DarkTheme.sidebarBackground)
            
            Divider().background(DarkTheme.borderDefault)
            
            HSplitView {
                // Left pane: Navigation
                VStack(spacing: 4) {
                    ForEach(SettingsSection.allCases) { section in
                        HStack(spacing: 8) {
                            Image(systemName: section.icon)
                                .font(.system(size: 13))
                                .foregroundColor(viewModel.selectedSection == section ? DarkTheme.primaryBlue : DarkTheme.textSecondary)
                                .frame(width: 18)
                            Text(section.rawValue)
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(viewModel.selectedSection == section ? DarkTheme.textPrimary : DarkTheme.textSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(viewModel.selectedSection == section ? DarkTheme.secondaryBackground : Color.clear)
                        .cornerRadius(6)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectedSection = section
                        }
                    }
                    Spacer()
                }
                .padding(12)
                .frame(width: 170)
                .background(DarkTheme.sidebarBackground)
                
                // Right pane: Form content
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        switch viewModel.selectedSection {
                        case .general:
                            VStack(alignment: .leading, spacing: 16) {
                                Text("General Preferences")
                                    .font(AppTypography.headline)
                                    .foregroundColor(DarkTheme.textPrimary)
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Default HTTP Method")
                                            .font(AppTypography.bodyMedium)
                                            .foregroundColor(DarkTheme.textPrimary)
                                        Text("Default method selected when creating a new request tab.")
                                            .font(AppTypography.caption)
                                            .foregroundColor(DarkTheme.textMuted)
                                    }
                                    Spacer()
                                    Picker("", selection: $viewModel.settings.defaultMethod) {
                                        Text("GET").tag("GET")
                                        Text("POST").tag("POST")
                                        Text("PUT").tag("PUT")
                                        Text("PATCH").tag("PATCH")
                                        Text("DELETE").tag("DELETE")
                                        Text("HEAD").tag("HEAD")
                                        Text("OPTIONS").tag("OPTIONS")
                                    }
                                    .frame(width: 110)
                                }
                                
                                Divider().background(DarkTheme.borderSubtle)
                                
                                Toggle(isOn: $viewModel.settings.saveToHistoryAutomatically) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Save Executed Requests to History")
                                            .font(AppTypography.bodyMedium)
                                            .foregroundColor(DarkTheme.textPrimary)
                                        Text("Automatically record outgoing requests and responses in local history.")
                                            .font(AppTypography.caption)
                                            .foregroundColor(DarkTheme.textMuted)
                                    }
                                }
                                .toggleStyle(.switch)
                                
                                Toggle(isOn: $viewModel.settings.trimWhitespaceInHeaders) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Trim Whitespace in Headers and Parameters")
                                            .font(AppTypography.bodyMedium)
                                            .foregroundColor(DarkTheme.textPrimary)
                                        Text("Strips accidental leading/trailing spaces when sending HTTP requests.")
                                            .font(AppTypography.caption)
                                            .foregroundColor(DarkTheme.textMuted)
                                    }
                                }
                                .toggleStyle(.switch)
                                
                                Toggle(isOn: $viewModel.settings.playCompletionSound) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Play Audio on Request Completion")
                                            .font(AppTypography.bodyMedium)
                                            .foregroundColor(DarkTheme.textPrimary)
                                        Text("Play system chime or alert sound when a network execution finishes.")
                                            .font(AppTypography.caption)
                                            .foregroundColor(DarkTheme.textMuted)
                                    }
                                }
                                .toggleStyle(.switch)
                                
                                Toggle(isOn: $viewModel.settings.confirmCloseDirtyTabs) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Confirm Closing Unsaved Tabs")
                                            .font(AppTypography.bodyMedium)
                                            .foregroundColor(DarkTheme.textPrimary)
                                        Text("Prompt for confirmation before closing tabs with unsaved edits.")
                                            .font(AppTypography.caption)
                                            .foregroundColor(DarkTheme.textMuted)
                                    }
                                }
                                .toggleStyle(.switch)
                            }
                            
                        case .network:
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Network Configuration")
                                    .font(AppTypography.headline)
                                    .foregroundColor(DarkTheme.textPrimary)
                                
                                HStack {
                                    Text("Default Timeout (seconds)")
                                        .font(AppTypography.body)
                                        .foregroundColor(DarkTheme.textPrimary)
                                    Spacer()
                                    TextField("", value: $viewModel.settings.defaultTimeout, format: .number)
                                        .frame(width: 60)
                                        .textFieldStyle(.roundedBorder)
                                }
                                
                                Toggle("Follow HTTP Redirects", isOn: $viewModel.settings.followRedirects)
                                    .toggleStyle(.switch)
                                
                                Toggle("Validate SSL / TLS Certificates", isOn: $viewModel.settings.validateSSL)
                                    .toggleStyle(.switch)
                                
                                Divider().background(DarkTheme.borderSubtle)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Default User-Agent")
                                            .font(AppTypography.bodyMedium)
                                            .foregroundColor(DarkTheme.textPrimary)
                                        
                                        Spacer()
                                        
                                        Menu {
                                            ForEach(UserAgentPresets.categories, id: \.self) { category in
                                                Section(category) {
                                                    ForEach(UserAgentPresets.presets.filter { $0.category == category }) { preset in
                                                        Button(preset.name) {
                                                            viewModel.settings.customUserAgent = preset.userAgent
                                                        }
                                                    }
                                                }
                                            }
                                            Divider()
                                            Button("Reset to Requestly Default") {
                                                viewModel.settings.customUserAgent = "Requestly/1.0 (macOS; Universal)"
                                            }
                                        } label: {
                                            HStack(spacing: 5) {
                                                Image(systemName: "list.bullet")
                                                    .font(.system(size: 10))
                                                Text("Choose Preset")
                                                    .font(AppTypography.captionMedium)
                                                Image(systemName: "chevron.down")
                                                    .font(.system(size: 8))
                                            }
                                            .foregroundColor(DarkTheme.primaryBlue)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(DarkTheme.elevatedBackground)
                                            .cornerRadius(5)
                                        }
                                        .menuStyle(.borderlessButton)
                                    }
                                    
                                    DarkTextField(placeholder: "Requestly/1.0 (macOS; Universal)", text: $viewModel.settings.customUserAgent)
                                    
                                    Text("Applied to outgoing HTTP requests when no custom User-Agent header is explicitly added. Choose from popular Desktop, Mobile, and Tablet browsers or API tools.")
                                        .font(AppTypography.caption)
                                        .foregroundColor(DarkTheme.textMuted)
                                }
                            }
                            
                        case .security:
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Security & Privacy Preferences")
                                    .font(AppTypography.headline)
                                    .foregroundColor(DarkTheme.textPrimary)
                                
                                Text("Requestly adheres to a local-first, zero-telemetry architecture with strict cryptographic and memory safeguards.")
                                    .font(AppTypography.caption)
                                    .foregroundColor(DarkTheme.textMuted)
                                
                                Toggle(isOn: $viewModel.settings.enforceHttpsOnly) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Enforce HTTPS Only")
                                            .font(AppTypography.bodyMedium)
                                            .foregroundColor(DarkTheme.textPrimary)
                                        Text("Disallow unencrypted HTTP traffic (except localhost / 127.0.0.1 for local API development).")
                                            .font(AppTypography.caption)
                                            .foregroundColor(DarkTheme.textMuted)
                                    }
                                }
                                .toggleStyle(.switch)
                                
                                Toggle(isOn: $viewModel.settings.validateSSL) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Validate SSL / TLS Certificates")
                                            .font(AppTypography.bodyMedium)
                                            .foregroundColor(DarkTheme.textPrimary)
                                        Text("Verify trust chains with Apple system roots. Prevents man-in-the-middle attacks.")
                                            .font(AppTypography.caption)
                                            .foregroundColor(DarkTheme.textMuted)
                                    }
                                }
                                .toggleStyle(.switch)
                                
                                Toggle(isOn: $viewModel.settings.redactCredentialsInHistory) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Redact Credentials in Request History")
                                            .font(AppTypography.bodyMedium)
                                            .foregroundColor(DarkTheme.textPrimary)
                                        Text("Mask bearer tokens, passwords, and API keys before writing to local SQLite database.")
                                            .font(AppTypography.caption)
                                            .foregroundColor(DarkTheme.textMuted)
                                    }
                                }
                                .toggleStyle(.switch)
                                
                                Toggle(isOn: $viewModel.settings.sanitizeSecretsInCurl) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Redact Secrets When Copying cURL")
                                            .font(AppTypography.bodyMedium)
                                            .foregroundColor(DarkTheme.textPrimary)
                                        Text("Sanitize authorization headers and API keys in exported cURL commands.")
                                            .font(AppTypography.caption)
                                            .foregroundColor(DarkTheme.textMuted)
                                    }
                                }
                                .toggleStyle(.switch)
                                
                                Divider().background(DarkTheme.borderSubtle)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Active Defenses")
                                        .font(AppTypography.captionMedium)
                                        .foregroundColor(DarkTheme.textSecondary)
                                    
                                    HStack(spacing: 8) {
                                        Image(systemName: "key.fill")
                                            .foregroundColor(DarkTheme.warningYellow)
                                            .font(.system(size: 11))
                                        Text("macOS Keychain: Hardware encrypted with FirstUnlockThisDeviceOnly")
                                            .font(AppTypography.caption)
                                            .foregroundColor(DarkTheme.textMuted)
                                    }
                                    
                                    HStack(spacing: 8) {
                                        Image(systemName: "shield.lefthalf.filled")
                                            .foregroundColor(DarkTheme.successGreen)
                                            .font(.system(size: 11))
                                        Text("Hardened Runtime: JIT-safe, no unauthorized memory execution, sandboxed file access")
                                            .font(AppTypography.caption)
                                            .foregroundColor(DarkTheme.textMuted)
                                    }
                                    
                                    HStack(spacing: 8) {
                                        Image(systemName: "cylinder.split.1x2")
                                            .foregroundColor(DarkTheme.primaryBlue)
                                            .font(.system(size: 11))
                                        Text("SQLite Zeroization: PRAGMA secure_delete wipes deleted records from disk")
                                            .font(AppTypography.caption)
                                            .foregroundColor(DarkTheme.textMuted)
                                    }
                                    
                                    HStack(spacing: 8) {
                                        Image(systemName: "network.badge.shield.half.filled")
                                            .foregroundColor(DarkTheme.successGreen)
                                            .font(.system(size: 11))
                                        Text("Scheme Guard: Strict HTTP/HTTPS filter blocks protocol smuggling and file:// access")
                                            .font(AppTypography.caption)
                                            .foregroundColor(DarkTheme.textMuted)
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(DarkTheme.elevatedBackground)
                                .cornerRadius(6)
                            }
                            
                        case .editor:
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Editor Preferences")
                                    .font(AppTypography.headline)
                                    .foregroundColor(DarkTheme.textPrimary)
                                
                                HStack {
                                    Text("Font Size (pt)")
                                        .font(AppTypography.body)
                                        .foregroundColor(DarkTheme.textPrimary)
                                    Spacer()
                                    TextField("", value: $viewModel.settings.editorFontSize, format: .number)
                                        .frame(width: 60)
                                        .textFieldStyle(.roundedBorder)
                                }
                                
                                HStack {
                                    Text("JSON Indentation (spaces)")
                                        .font(AppTypography.body)
                                        .foregroundColor(DarkTheme.textPrimary)
                                    Spacer()
                                    Picker("", selection: $viewModel.settings.jsonIndentationSpaces) {
                                        Text("2 spaces (Default)").tag(2)
                                        Text("4 spaces").tag(4)
                                    }
                                    .frame(width: 150)
                                }
                                
                                Toggle("Show Line Numbers", isOn: $viewModel.settings.showLineNumbers)
                                    .toggleStyle(.switch)
                                
                                Toggle("Word Wrap", isOn: $viewModel.settings.wordWrap)
                                    .toggleStyle(.switch)
                                
                                Toggle("Syntax Highlighting", isOn: $viewModel.settings.syntaxHighlightingEnabled)
                                    .toggleStyle(.switch)
                            }
                            
                        case .response:
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Response Inspector Preferences")
                                    .font(AppTypography.headline)
                                    .foregroundColor(DarkTheme.textPrimary)
                                
                                Toggle("Automatically Pretty-Print Valid JSON", isOn: $viewModel.settings.autoFormatJSON)
                                    .toggleStyle(.switch)
                                
                                HStack {
                                    Text("Max Response Size (MB)")
                                        .font(AppTypography.body)
                                        .foregroundColor(DarkTheme.textPrimary)
                                    Spacer()
                                    TextField("", value: $viewModel.settings.maxResponseSizeMB, format: .number)
                                        .frame(width: 60)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                            
                        case .storage:
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Storage & History")
                                    .font(AppTypography.headline)
                                    .foregroundColor(DarkTheme.textPrimary)
                                
                                HStack {
                                    Text("History Retention (days)")
                                        .font(AppTypography.body)
                                        .foregroundColor(DarkTheme.textPrimary)
                                    Spacer()
                                    TextField("", value: $viewModel.settings.historyRetentionDays, format: .number)
                                        .frame(width: 60)
                                        .textFieldStyle(.roundedBorder)
                                }
                                
                                Divider().background(DarkTheme.borderSubtle)
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    Button(action: {
                                        viewModel.showClearConfirmDialog = true
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "trash")
                                                .font(.system(size: 11))
                                            Text("Clear All Request History")
                                                .font(AppTypography.bodyMedium)
                                        }
                                        .foregroundColor(DarkTheme.errorRed)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(DarkTheme.errorRed.opacity(0.12))
                                        .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    if viewModel.showClearSuccessMessage {
                                        HStack(spacing: 8) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(DarkTheme.successGreen)
                                            Text("All request history has been successfully cleared.")
                                                .font(AppTypography.captionMedium)
                                                .foregroundColor(DarkTheme.successGreen)
                                        }
                                        .padding(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(DarkTheme.successGreen.opacity(0.12))
                                        .cornerRadius(6)
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(DarkTheme.successGreen.opacity(0.3), lineWidth: 1))
                                        .transition(.opacity)
                                    }
                                }
                            }
                            
                        case .shortcuts:
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Keyboard Shortcuts")
                                    .font(AppTypography.headline)
                                    .foregroundColor(DarkTheme.textPrimary)
                                
                                let shortcuts = [
                                    ("Send Request", "⌘ Enter"),
                                    ("New Request", "⌘ N"),
                                    ("New Tab", "⌘ T"),
                                    ("Close Tab", "⌘ W"),
                                    ("Save Request", "⌘ S"),
                                    ("Cancel Request", "⌘ ."),
                                    ("Quick Command Palette", "⌘ K"),
                                    ("Copy as cURL", "⌥ ⌘ C")
                                ]
                                
                                ForEach(shortcuts, id: \.0) { item in
                                    HStack {
                                        Text(item.0)
                                            .font(AppTypography.body)
                                            .foregroundColor(DarkTheme.textPrimary)
                                        Spacer()
                                        Text(item.1)
                                            .font(AppTypography.codeSmall)
                                            .foregroundColor(DarkTheme.textSecondary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(DarkTheme.elevatedBackground)
                                            .cornerRadius(4)
                                    }
                                    .padding(.vertical, 4)
                                    Divider().background(DarkTheme.borderSubtle)
                                }
                            }
                            
                        case .about:
                            VStack(spacing: 12) {
                                if let icon = NSImage(named: "AppIcon") ?? Bundle.main.image(forResource: "AppIcon") {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 64, height: 64)
                                        .cornerRadius(14)
                                } else {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(DarkTheme.primaryBlue)
                                            .frame(width: 56, height: 56)
                                        Image(systemName: "bolt.horizontal.fill")
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                Text("Requestly for macOS")
                                    .font(AppTypography.title)
                                    .foregroundColor(DarkTheme.textPrimary)
                                
                                Text("Version 1.0 (Universal Apple Silicon + Intel)")
                                    .font(AppTypography.caption)
                                    .foregroundColor(DarkTheme.textMuted)
                                
                                Text("Identifier: com.requestly.sysninja")
                                    .font(AppTypography.codeSmall)
                                    .foregroundColor(DarkTheme.textMuted)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(DarkTheme.elevatedBackground)
                                    .cornerRadius(4)
                                
                                Text("A fast, lightweight, native macOS HTTP client & API testing tool. Built with Swift, SwiftUI, and AppKit with zero web-view bloat.")
                                    .font(AppTypography.body)
                                    .foregroundColor(DarkTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                                
                                Divider()
                                    .background(DarkTheme.borderSubtle)
                                    .padding(.vertical, 8)
                                
                                HStack(spacing: 4) {
                                    Text("Developed with")
                                        .font(AppTypography.bodyMedium)
                                        .foregroundColor(DarkTheme.textSecondary)
                                    Text("❤️")
                                        .font(.system(size: 13))
                                        .foregroundColor(DarkTheme.errorRed)
                                    Text("by Khalequzzaman")
                                        .font(AppTypography.bodyMedium)
                                        .foregroundColor(DarkTheme.textPrimary)
                                }
                                
                                Text("Local-first • Privacy-focused • No telemetry")
                                    .font(AppTypography.caption)
                                    .foregroundColor(DarkTheme.textMuted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 16)
                        }
                    }
                    .padding(20)
                }
                .background(DarkTheme.editorBackground)
            }
        }
        .frame(width: 660, height: 480)
        .background(DarkTheme.mainBackground)
        .forceDarkMode()
        .alert("Clear All Request History?", isPresented: $viewModel.showClearConfirmDialog) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All History", role: .destructive) {
                viewModel.clearHistory()
            }
        } message: {
            Text("Are you sure you want to delete all stored HTTP request history? This action cannot be undone.")
        }
    }
}
