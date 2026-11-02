import SwiftUI

public struct ResponseViewerView: View {
    @ObservedObject var viewModel: ResponseViewerViewModel
    
    public init(viewModel: ResponseViewerViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if let resp = viewModel.response {
                // Response Header / Status Bar
                HStack(spacing: 16) {
                    StatusBadgeView(statusCode: resp.statusCode, statusDescription: resp.statusDescription)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                            .foregroundColor(DarkTheme.textSecondary)
                        Text(TimeFormatter.formatDurationMs(resp.durationMs))
                            .font(AppTypography.captionMedium)
                            .foregroundColor(DarkTheme.textPrimary)
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 11))
                            .foregroundColor(DarkTheme.textSecondary)
                        Text(ByteFormatter.format(resp.byteCount))
                            .font(AppTypography.captionMedium)
                            .foregroundColor(DarkTheme.textPrimary)
                    }
                    
                    Spacer()
                    
                    // Toolbar Buttons
                    HStack(spacing: 8) {
                        Button(action: {
                            viewModel.isSearchVisible.toggle()
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 12))
                                .foregroundColor(viewModel.isSearchVisible ? DarkTheme.primaryBlue : DarkTheme.textSecondary)
                                .padding(5)
                                .background(DarkTheme.elevatedBackground)
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        .help("Search response (⌘F)")
                        
                        Button(action: {
                            viewModel.downloadResponse()
                        }) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 12))
                                .foregroundColor(DarkTheme.textSecondary)
                                .padding(5)
                                .background(DarkTheme.elevatedBackground)
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        .help("Save response to file")
                        
                        Button(action: {
                            if viewModel.activeTab == .pretty {
                                viewModel.copyPrettyJSON()
                            } else {
                                viewModel.copyRawBody()
                            }
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12))
                                .foregroundColor(DarkTheme.textSecondary)
                                .padding(5)
                                .background(DarkTheme.elevatedBackground)
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        .help("Copy Response")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(DarkTheme.mainBackground)
                
                Divider().background(DarkTheme.borderDefault)
                
                // Response Tabs
                HStack(spacing: 2) {
                    ForEach(ResponseViewerTab.allCases) { tab in
                        Button(action: {
                            viewModel.activeTab = tab
                        }) {
                            HStack(spacing: 4) {
                                Text(tab.rawValue)
                                    .font(AppTypography.captionMedium)
                                
                                if tab == .headers {
                                    Text("\(resp.headerList.count)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(DarkTheme.textSecondary)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(DarkTheme.elevatedBackground)
                                        .clipShape(Capsule())
                                } else if tab == .cookies && !resp.cookies.isEmpty {
                                    Text("\(resp.cookies.count)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(DarkTheme.primaryBlue)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(DarkTheme.primaryBlue.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                            .foregroundColor(viewModel.activeTab == tab ? DarkTheme.textPrimary : DarkTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(viewModel.activeTab == tab ? DarkTheme.editorBackground : Color.clear)
                            .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background(DarkTheme.mainBackground)
                
                Divider().background(DarkTheme.borderSubtle)
                
                // Search Bar overlay when visible
                if viewModel.isSearchVisible {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(DarkTheme.textMuted)
                        TextField("Search in response body...", text: $viewModel.searchQuery)
                            .font(AppTypography.caption)
                            .foregroundColor(DarkTheme.textPrimary)
                            .textFieldStyle(.plain)
                        if !viewModel.searchQuery.isEmpty {
                            Button(action: {
                                viewModel.searchQuery = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(DarkTheme.textMuted)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DarkTheme.secondaryBackground)
                    Divider().background(DarkTheme.borderSubtle)
                }
                
                // Tab Content Area
                ZStack {
                    DarkTheme.editorBackground.ignoresSafeArea()
                    
                    switch viewModel.activeTab {
                    case .pretty:
                        JSONPrettyTreeView(viewModel: viewModel)
                    case .raw:
                        RawResponseView(viewModel: viewModel)
                    case .preview:
                        PreviewResponseView(viewModel: viewModel)
                    case .headers:
                        ResponseHeadersView(viewModel: viewModel)
                    case .cookies:
                        ResponseCookiesView(viewModel: viewModel)
                    }
                }
            } else {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "network")
                        .font(.system(size: 36))
                        .foregroundColor(DarkTheme.textMuted.opacity(0.7))
                    Text("Ready to Send Request")
                        .font(AppTypography.headline)
                        .foregroundColor(DarkTheme.textSecondary)
                    Text("Press Send or ⌘Enter to execute the HTTP request and inspect the response.")
                        .font(AppTypography.caption)
                        .foregroundColor(DarkTheme.textMuted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DarkTheme.editorBackground)
            }
        }
    }
}
