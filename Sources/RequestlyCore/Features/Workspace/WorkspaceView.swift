import SwiftUI

public struct WorkspaceView: View {
    @StateObject private var viewModel = WorkspaceViewModel()
    
    public init() {}
    
    public var body: some View {
        HSplitView {
            // Part A: Sidebar
            SidebarView(viewModel: viewModel.sidebarViewModel)
                .frame(minWidth: 220, idealWidth: 260, maxWidth: 320)
            
            // Central Workspace (Tabs + Editor & Response Viewer Split)
            VStack(spacing: 0) {
                // Top Tab Bar & Environment Selector
                HStack(spacing: 0) {
                    // Request Tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 1) {
                            ForEach(viewModel.tabs) { tab in
                                HStack(spacing: 6) {
                                    MethodBadgeView(method: tab.request.method.rawValue, fontSize: 8)
                                    
                                    Text(tab.request.name.isEmpty ? "Untitled" : tab.request.name)
                                        .font(AppTypography.captionMedium)
                                        .foregroundColor(viewModel.activeTabId == tab.id ? DarkTheme.textPrimary : DarkTheme.textSecondary)
                                        .lineLimit(1)
                                    
                                    Button(action: {
                                        viewModel.closeTab(id: tab.id)
                                    }) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(DarkTheme.textMuted)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(viewModel.activeTabId == tab.id ? DarkTheme.editorBackground : DarkTheme.mainBackground)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.activeTabId = tab.id
                                    viewModel.updateActiveViewModels()
                                }
                            }
                            
                            // Add Tab Button
                            Button(action: {
                                viewModel.newTab()
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 11))
                                    .foregroundColor(DarkTheme.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 7)
                            }
                            .buttonStyle(.plain)
                            .help("New Tab (⌘T)")
                        }
                    }
                    
                    Spacer()
                    
                    // Quick Command Palette Button
                    Button(action: {
                        viewModel.showCommandPalette = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "command")
                                .font(.system(size: 10))
                            Text("⌘K")
                                .font(AppTypography.caption)
                        }
                        .foregroundColor(DarkTheme.textMuted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DarkTheme.elevatedBackground)
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .help("Command Palette (⌘K)")
                    .padding(.trailing, 8)
                    
                    // Environment Selector Menu
                    Menu {
                        Button("No Environment") {
                            viewModel.activeEnvironment = nil
                        }
                        Divider()
                        ForEach(viewModel.environments) { env in
                            Button(env.name) {
                                viewModel.activeEnvironment = env
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(viewModel.activeEnvironment != nil ? DarkTheme.successGreen : DarkTheme.textMuted)
                                .frame(width: 6, height: 6)
                            Text(viewModel.activeEnvironment?.name ?? "No Environment")
                                .font(AppTypography.captionMedium)
                                .foregroundColor(DarkTheme.textPrimary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8))
                                .foregroundColor(DarkTheme.textSecondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(DarkTheme.elevatedBackground)
                        .cornerRadius(5)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    .padding(.trailing, 12)
                }
                .background(DarkTheme.mainBackground)
                
                Divider().background(DarkTheme.borderDefault)
                
                // Split View: Part B (Request Editor) & Part C (Response Viewer)
                VSplitView {
                    if let editorVM = viewModel.activeEditorViewModel {
                        RequestEditorView(viewModel: editorVM)
                            .frame(minHeight: 220)
                    }
                    
                    ResponseViewerView(viewModel: viewModel.activeResponseViewModel)
                        .frame(minHeight: 220)
                }
            }
            .frame(minWidth: 500)
            .background(DarkTheme.mainBackground)
        }
        .background(DarkTheme.mainBackground)
        .forceDarkMode()
        // Keyboard Shortcuts
        .keyboardShortcut("n", modifiers: [.command])
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NewRequestShortcut"))) { _ in
            viewModel.newTab()
        }
        // Modals & Sheets
        .sheet(isPresented: $viewModel.showEnvironmentsSheet) {
            EnvironmentManagerView(viewModel: viewModel.environmentViewModel)
                .onDisappear {
                    viewModel.loadEnvironments()
                }
        }
        .sheet(isPresented: $viewModel.showImportSheet) {
            ImportModalView(
                onImportRequest: { imported in
                    viewModel.openInNewOrCurrentTab(request: imported)
                },
                onImportFinished: {
                    viewModel.sidebarViewModel.loadData()
                }
            )
        }
        .sheet(isPresented: $viewModel.showSettingsSheet) {
            SettingsView()
        }
        .sheet(isPresented: $viewModel.showCommandPalette) {
            CommandPaletteView(viewModel: viewModel)
        }
    }
}
