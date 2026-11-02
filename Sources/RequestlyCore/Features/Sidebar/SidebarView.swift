import SwiftUI

public struct SidebarView: View {
    @ObservedObject var viewModel: SidebarViewModel
    
    public init(viewModel: SidebarViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // App Header
            HStack(spacing: 10) {
                if let icon = NSImage(named: "AppIcon") ?? Bundle.main.image(forResource: "AppIcon") {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                        .cornerRadius(6)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(DarkTheme.primaryBlue)
                            .frame(width: 28, height: 28)
                        Image(systemName: "bolt.horizontal.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text("Requestly")
                            .font(AppTypography.headline)
                            .foregroundColor(DarkTheme.textPrimary)
                        Text("v1.0")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(DarkTheme.textMuted)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(DarkTheme.elevatedBackground)
                            .cornerRadius(3)
                    }
                    Text("API Client & Request Tester")
                        .font(.system(size: 10))
                        .foregroundColor(DarkTheme.textMuted)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)
            
            // New Request Action Button
            Button(action: {
                viewModel.onNewRequest?()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                    Text("New Request")
                        .font(AppTypography.bodyMedium)
                    Spacer()
                    Text("⌘N")
                        .font(AppTypography.caption)
                        .foregroundColor(DarkTheme.textMuted)
                }
                .foregroundColor(DarkTheme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(DarkTheme.secondaryBackground)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(DarkTheme.borderDefault, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
            
            // Section Switcher (Collections / History)
            Picker("", selection: $viewModel.selectedSection) {
                Text("Collections").tag(SidebarSection.collections)
                Text("History").tag(SidebarSection.history)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DarkTheme.textMuted)
                    .font(.system(size: 11))
                TextField("Search...", text: $viewModel.searchQuery)
                    .font(AppTypography.caption)
                    .foregroundColor(DarkTheme.textPrimary)
                    .textFieldStyle(.plain)
                if !viewModel.searchQuery.isEmpty {
                    Button(action: {
                        viewModel.searchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DarkTheme.textMuted)
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(DarkTheme.editorBackground)
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(DarkTheme.borderDefault, lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            Divider().background(DarkTheme.borderSubtle)
            
            // Main Sidebar Content Area
            if viewModel.selectedSection == .collections {
                VStack(spacing: 0) {
                    // Collections Action Bar
                    HStack {
                        Text("COLLECTIONS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(DarkTheme.textMuted)
                        Spacer()
                        Button(action: {
                            viewModel.newCollectionName = ""
                            viewModel.showNewCollectionSheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 11))
                                .foregroundColor(DarkTheme.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .help("Create Collection")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            let filteredCollections = viewModel.collections.filter {
                                viewModel.searchQuery.isEmpty || $0.name.localizedCaseInsensitiveContains(viewModel.searchQuery)
                            }
                            
                            if filteredCollections.isEmpty {
                                Text("No collections yet.\nClick + to create one.")
                                    .font(AppTypography.caption)
                                    .foregroundColor(DarkTheme.textMuted)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 24)
                                    .frame(maxWidth: .infinity)
                            } else {
                                ForEach(filteredCollections) { coll in
                                    CollectionRowView(collection: coll, viewModel: viewModel)
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 16)
                    }
                }
            } else {
                // History Section
                VStack(spacing: 0) {
                    HStack {
                        Text("HISTORY")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(DarkTheme.textMuted)
                        Spacer()
                        if !viewModel.historyItems.isEmpty {
                            Button("Clear") {
                                viewModel.clearHistory()
                            }
                            .font(AppTypography.caption)
                            .foregroundColor(DarkTheme.errorRed)
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            let filteredHistory = viewModel.historyItems.filter {
                                viewModel.searchQuery.isEmpty ||
                                $0.url.localizedCaseInsensitiveContains(viewModel.searchQuery) ||
                                $0.requestName.localizedCaseInsensitiveContains(viewModel.searchQuery)
                            }
                            
                            if filteredHistory.isEmpty {
                                Text("No request history yet.")
                                    .font(AppTypography.caption)
                                    .foregroundColor(DarkTheme.textMuted)
                                    .padding(.top, 24)
                                    .frame(maxWidth: .infinity)
                            } else {
                                ForEach(filteredHistory) { item in
                                    Button(action: {
                                        viewModel.onSelectRequest?(item.requestSnapshot)
                                    }) {
                                        HStack(spacing: 6) {
                                            MethodBadgeView(method: item.method.rawValue, fontSize: 8)
                                            
                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(item.url)
                                                    .font(AppTypography.codeSmall)
                                                    .foregroundColor(DarkTheme.textPrimary)
                                                    .lineLimit(1)
                                                
                                                HStack(spacing: 8) {
                                                    Text("\(item.statusCode)")
                                                        .foregroundColor(item.statusCode >= 200 && item.statusCode < 300 ? DarkTheme.successGreen : DarkTheme.errorRed)
                                                    Text(TimeFormatter.formatDurationMs(item.durationMs))
                                                    Text(TimeFormatter.formatRelativeTime(item.timestamp))
                                                }
                                                .font(.system(size: 10))
                                                .foregroundColor(DarkTheme.textMuted)
                                            }
                                            Spacer()
                                        }
                                        .padding(.vertical, 5)
                                        .padding(.horizontal, 8)
                                        .background(DarkTheme.sidebarBackground)
                                        .cornerRadius(4)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 16)
                    }
                }
            }
            
            Divider().background(DarkTheme.borderSubtle)
            
            // Bottom Action Bar: Environments, Import/Export, Settings
            HStack(spacing: 12) {
                Button(action: {
                    viewModel.onOpenEnvironments?()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                        Text("Env")
                    }
                    .font(AppTypography.captionMedium)
                    .foregroundColor(DarkTheme.textSecondary)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    viewModel.onOpenImport?()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import")
                    }
                    .font(AppTypography.captionMedium)
                    .foregroundColor(DarkTheme.textSecondary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {
                    viewModel.onOpenSettings?()
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13))
                        .foregroundColor(DarkTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(DarkTheme.sidebarBackground)
        }
        .frame(minWidth: 240, idealWidth: 280, maxWidth: 360)
        .background(DarkTheme.sidebarBackground)
        // Sheets
        .sheet(isPresented: $viewModel.showNewCollectionSheet) {
            VStack(spacing: 14) {
                Text("Create New Collection")
                    .font(AppTypography.headline)
                    .foregroundColor(DarkTheme.textPrimary)
                
                DarkTextField(placeholder: "Collection Name", text: $viewModel.newCollectionName)
                    .frame(width: 260)
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        viewModel.showNewCollectionSheet = false
                    }
                    .foregroundColor(DarkTheme.textSecondary)
                    
                    Button("Create") {
                        viewModel.createCollection(name: viewModel.newCollectionName)
                        viewModel.showNewCollectionSheet = false
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(DarkTheme.primaryBlue)
                    .cornerRadius(5)
                }
            }
            .padding(24)
            .background(DarkTheme.mainBackground)
            .forceDarkMode()
        }
        .sheet(isPresented: $viewModel.showNewFolderSheet) {
            VStack(spacing: 14) {
                Text("Create New Folder")
                    .font(AppTypography.headline)
                    .foregroundColor(DarkTheme.textPrimary)
                
                DarkTextField(placeholder: "Folder Name", text: $viewModel.newFolderName)
                    .frame(width: 260)
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        viewModel.showNewFolderSheet = false
                    }
                    .foregroundColor(DarkTheme.textSecondary)
                    
                    Button("Create") {
                        if let coll = viewModel.targetCollectionForFolder {
                            viewModel.createFolder(name: viewModel.newFolderName, in: coll.id)
                        }
                        viewModel.showNewFolderSheet = false
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(DarkTheme.primaryBlue)
                    .cornerRadius(5)
                }
            }
            .padding(24)
            .background(DarkTheme.mainBackground)
            .forceDarkMode()
        }
    }
}
