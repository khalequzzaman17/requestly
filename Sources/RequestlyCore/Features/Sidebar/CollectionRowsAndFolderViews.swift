import SwiftUI

public struct CollectionRowView: View {
    let collection: CollectionModel
    @ObservedObject var viewModel: SidebarViewModel
    
    public init(collection: CollectionModel, viewModel: SidebarViewModel) {
        self.collection = collection
        self.viewModel = viewModel
    }
    
    private var isExpanded: Bool {
        viewModel.expandedCollectionIds.contains(collection.id)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Collection Header
            HStack(spacing: 6) {
                Button(action: {
                    if isExpanded {
                        viewModel.expandedCollectionIds.remove(collection.id)
                    } else {
                        viewModel.expandedCollectionIds.insert(collection.id)
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(DarkTheme.textSecondary)
                        .frame(width: 12)
                }
                .buttonStyle(.plain)
                
                Image(systemName: "folder.fill")
                    .foregroundColor(DarkTheme.warningYellow)
                    .font(.system(size: 12))
                
                Text(collection.name)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(DarkTheme.textPrimary)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
            .contextMenu {
                Button("New Folder") {
                    viewModel.targetCollectionForFolder = collection
                    viewModel.newFolderName = ""
                    viewModel.showNewFolderSheet = true
                }
                Divider()
                Button("Delete Collection", role: .destructive) {
                    viewModel.deleteCollection(collection)
                }
            }
            
            // Nested Folders and Requests
            if isExpanded {
                VStack(alignment: .leading, spacing: 2) {
                    // Folders at root of collection
                    let rootFolders = viewModel.folders.filter { $0.collectionId == collection.id && $0.parentFolderId == nil }
                    ForEach(rootFolders) { folder in
                        FolderRowView(folder: folder, viewModel: viewModel, depth: 1)
                    }
                    
                    // Requests directly in collection (no folder)
                    let rootRequests = viewModel.savedRequests.filter { $0.collectionId == collection.id && $0.folderId == nil }
                    ForEach(rootRequests) { req in
                        RequestRowView(savedRequest: req, viewModel: viewModel, depth: 1)
                    }
                }
            }
        }
    }
}

public struct FolderRowView: View {
    let folder: FolderModel
    @ObservedObject var viewModel: SidebarViewModel
    let depth: Int
    
    public init(folder: FolderModel, viewModel: SidebarViewModel, depth: Int = 1) {
        self.folder = folder
        self.viewModel = viewModel
        self.depth = depth
    }
    
    private var isExpanded: Bool {
        viewModel.expandedFolderIds.contains(folder.id)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Spacer().frame(width: CGFloat(depth * 12))
                
                Button(action: {
                    if isExpanded {
                        viewModel.expandedFolderIds.remove(folder.id)
                    } else {
                        viewModel.expandedFolderIds.insert(folder.id)
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(DarkTheme.textSecondary)
                        .frame(width: 12)
                }
                .buttonStyle(.plain)
                
                Image(systemName: isExpanded ? "folder.open" : "folder")
                    .foregroundColor(DarkTheme.textSecondary)
                    .font(.system(size: 11))
                
                Text(folder.name)
                    .font(AppTypography.body)
                    .foregroundColor(DarkTheme.textPrimary)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.vertical, 3)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
            .contextMenu {
                Button("Delete Folder", role: .destructive) {
                    viewModel.deleteFolder(folder)
                }
            }
            
            if isExpanded {
                // Subfolders
                let subFolders = viewModel.folders.filter { $0.parentFolderId == folder.id }
                ForEach(subFolders) { sub in
                    FolderRowView(folder: sub, viewModel: viewModel, depth: depth + 1)
                }
                
                // Requests in this folder
                let folderReqs = viewModel.savedRequests.filter { $0.folderId == folder.id }
                ForEach(folderReqs) { req in
                    RequestRowView(savedRequest: req, viewModel: viewModel, depth: depth + 1)
                }
            }
        }
    }
}

public struct RequestRowView: View {
    let savedRequest: SavedRequestModel
    @ObservedObject var viewModel: SidebarViewModel
    let depth: Int
    
    public init(savedRequest: SavedRequestModel, viewModel: SidebarViewModel, depth: Int = 1) {
        self.savedRequest = savedRequest
        self.viewModel = viewModel
        self.depth = depth
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            Spacer().frame(width: CGFloat(depth * 12 + 14))
            
            MethodBadgeView(method: savedRequest.request.method.rawValue, fontSize: 8)
            
            Text(savedRequest.request.name)
                .font(AppTypography.body)
                .foregroundColor(DarkTheme.textPrimary)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.onSelectRequest?(savedRequest.request)
        }
        .contextMenu {
            Button("Duplicate") {
                viewModel.duplicateRequest(savedRequest)
            }
            Divider()
            Button("Delete Request", role: .destructive) {
                viewModel.deleteRequest(savedRequest)
            }
        }
    }
}
