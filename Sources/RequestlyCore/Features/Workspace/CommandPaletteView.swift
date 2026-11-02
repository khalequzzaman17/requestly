import SwiftUI

public struct CommandPaletteItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let subtitle: String
    public let icon: String
    public let shortcut: String?
    public let action: () -> Void
}

public final class CommandPaletteViewModel: ObservableObject {
    @Published public var searchText: String = ""
    public init() {}
}

public struct CommandPaletteView: View {
    @ObservedObject var viewModel: WorkspaceViewModel
    @StateObject private var paletteVM = CommandPaletteViewModel()
    @Environment(\.dismiss) private var dismiss
    
    public init(viewModel: WorkspaceViewModel) {
        self.viewModel = viewModel
    }
    
    private var allCommands: [CommandPaletteItem] {
        var items: [CommandPaletteItem] = [
            CommandPaletteItem(
                title: "Send Request",
                subtitle: "Execute current active HTTP request",
                icon: "paperplane.fill",
                shortcut: "⌘↵",
                action: {
                    dismiss()
                    viewModel.executeActiveRequest()
                }
            ),
            CommandPaletteItem(
                title: "New Request Tab",
                subtitle: "Open a new blank request tab",
                icon: "plus.circle.fill",
                shortcut: "⌘T",
                action: {
                    dismiss()
                    viewModel.newTab()
                }
            ),
            CommandPaletteItem(
                title: "Save Request",
                subtitle: "Save current request to collection",
                icon: "bookmark.fill",
                shortcut: "⌘S",
                action: {
                    dismiss()
                    viewModel.saveActiveRequest()
                }
            ),
            CommandPaletteItem(
                title: "Copy as cURL",
                subtitle: "Copy reproducible cURL command to clipboard",
                icon: "terminal.fill",
                shortcut: "⌥⌘C",
                action: {
                    dismiss()
                    if let req = viewModel.activeEditorViewModel?.request {
                        let curl = CurlParserAndExporter.shared.export(request: req)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(curl, forType: .string)
                    }
                }
            ),
            CommandPaletteItem(
                title: "Manage Environments",
                subtitle: "View and edit environment variables",
                icon: "slider.horizontal.3",
                shortcut: nil,
                action: {
                    dismiss()
                    viewModel.showEnvironmentsSheet = true
                }
            ),
            CommandPaletteItem(
                title: "Import cURL or Postman",
                subtitle: "Import requests from cURL command or Postman collection",
                icon: "square.and.arrow.down.fill",
                shortcut: nil,
                action: {
                    dismiss()
                    viewModel.showImportSheet = true
                }
            ),
            CommandPaletteItem(
                title: "Settings",
                subtitle: "Configure network, editor, and response preferences",
                icon: "gearshape.fill",
                shortcut: "⌘,",
                action: {
                    dismiss()
                    viewModel.showSettingsSheet = true
                }
            ),
            CommandPaletteItem(
                title: "Clear Request History",
                subtitle: "Erase all past request execution records",
                icon: "trash.fill",
                shortcut: nil,
                action: {
                    dismiss()
                    viewModel.sidebarViewModel.clearHistory()
                }
            )
        ]
        
        // Add environments as switch actions
        for env in viewModel.environments {
            items.append(CommandPaletteItem(
                title: "Switch Environment: \(env.name)",
                subtitle: "\(env.variables.count) variables",
                icon: "globe",
                shortcut: nil,
                action: {
                    dismiss()
                    viewModel.activeEnvironment = env
                }
            ))
        }
        
        // Add saved requests
        for saved in viewModel.sidebarViewModel.savedRequests {
            items.append(CommandPaletteItem(
                title: "Open: \(saved.request.name)",
                subtitle: "\(saved.request.method.rawValue) \(saved.request.url)",
                icon: "doc.text.fill",
                shortcut: nil,
                action: {
                    dismiss()
                    viewModel.openInNewOrCurrentTab(request: saved.request)
                }
            ))
        }
        
        return items
    }
    
    private var filteredCommands: [CommandPaletteItem] {
        if paletteVM.searchText.isEmpty {
            return allCommands
        }
        return allCommands.filter {
            $0.title.localizedCaseInsensitiveContains(paletteVM.searchText) ||
            $0.subtitle.localizedCaseInsensitiveContains(paletteVM.searchText)
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Search Input
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DarkTheme.textMuted)
                    .font(.system(size: 15))
                TextField("Type a command or search requests (e.g. 'send', 'dev', 'import')...", text: $paletteVM.searchText)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(DarkTheme.textPrimary)
                    .textFieldStyle(.plain)
                
                Button("esc") {
                    dismiss()
                }
                .font(AppTypography.caption)
                .foregroundColor(DarkTheme.textMuted)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(DarkTheme.elevatedBackground)
                .cornerRadius(4)
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(DarkTheme.sidebarBackground)
            
            Divider().background(DarkTheme.borderDefault)
            
            // Results List
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(filteredCommands) { cmd in
                        HStack(spacing: 10) {
                            Image(systemName: cmd.icon)
                                .font(.system(size: 13))
                                .foregroundColor(DarkTheme.primaryBlue)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(cmd.title)
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(DarkTheme.textPrimary)
                                Text(cmd.subtitle)
                                    .font(AppTypography.caption)
                                    .foregroundColor(DarkTheme.textMuted)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            if let sc = cmd.shortcut {
                                Text(sc)
                                    .font(AppTypography.codeSmall)
                                    .foregroundColor(DarkTheme.textSecondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(DarkTheme.elevatedBackground)
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            cmd.action()
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .frame(width: 540, height: 380)
        .background(DarkTheme.mainBackground)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(DarkTheme.borderDefault, lineWidth: 1)
        )
        .forceDarkMode()
    }
}
