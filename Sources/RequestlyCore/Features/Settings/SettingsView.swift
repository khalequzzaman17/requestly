import SwiftUI

public enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case network = "Network"
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
    
    public init() {
        if let loaded = try? DatabaseService.shared.loadSettings() {
            self.settings = loaded
        }
    }
    
    public func save() {
        try? DatabaseService.shared.saveSettings(settings)
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
                Button("Done") {
                    viewModel.save()
                    dismiss()
                }
                .font(AppTypography.captionMedium)
                .foregroundColor(DarkTheme.primaryBlue)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
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
                            VStack(alignment: .leading, spacing: 12) {
                                Text("General Preferences")
                                    .font(AppTypography.headline)
                                    .foregroundColor(DarkTheme.textPrimary)
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Appearance")
                                            .font(AppTypography.bodyMedium)
                                            .foregroundColor(DarkTheme.textPrimary)
                                        Text("Requestly is permanently designed in Dark Mode for developers.")
                                            .font(AppTypography.caption)
                                            .foregroundColor(DarkTheme.textMuted)
                                    }
                                    Spacer()
                                    Text("Dark Mode Only")
                                        .font(AppTypography.captionMedium)
                                        .foregroundColor(DarkTheme.textSecondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(DarkTheme.elevatedBackground)
                                        .cornerRadius(4)
                                }
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
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Custom User-Agent")
                                        .font(AppTypography.body)
                                        .foregroundColor(DarkTheme.textPrimary)
                                    DarkTextField(placeholder: "Requestly/1.0", text: $viewModel.settings.customUserAgent)
                                }
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
                                
                                Button("Clear All Request History") {
                                    try? DatabaseService.shared.clearHistory()
                                }
                                .foregroundColor(DarkTheme.errorRed)
                                .buttonStyle(.plain)
                            }
                            
                        case .shortcuts:
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Keyboard Shortcuts")
                                    .font(AppTypography.headline)
                                    .foregroundColor(DarkTheme.textPrimary)
                                
                                let shortcuts = [
                                    ("Send Request", "⌘ Enter"),
                                    ("New Request", "⌘ N"),
                                    ("Save Request", "⌘ S"),
                                    ("New Tab", "⌘ T"),
                                    ("Close Tab", "⌘ W"),
                                    ("Quick Command / Search", "⌘ K"),
                                    ("Copy cURL", "⌥ ⌘ C")
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
                                
                                Text("A fast, lightweight, native macOS HTTP client & API testing tool. Built with Swift, SwiftUI, and AppKit with zero web-view bloat.")
                                    .font(AppTypography.body)
                                    .foregroundColor(DarkTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)
                        }
                    }
                    .padding(20)
                }
                .background(DarkTheme.editorBackground)
            }
        }
        .frame(width: 640, height: 460)
        .background(DarkTheme.mainBackground)
        .forceDarkMode()
    }
}
