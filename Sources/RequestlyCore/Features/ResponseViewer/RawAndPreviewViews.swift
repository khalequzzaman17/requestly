import SwiftUI
import AppKit

public struct RawResponseView: View {
    @ObservedObject var viewModel: ResponseViewerViewModel
    
    public init(viewModel: ResponseViewerViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(viewModel.response?.bodyData.count ?? 0) bytes")
                    .font(AppTypography.caption)
                    .foregroundColor(DarkTheme.textSecondary)
                Spacer()
                Button(action: {
                    viewModel.copyRawBody()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy Raw")
                    }
                    .font(AppTypography.captionMedium)
                    .foregroundColor(DarkTheme.primaryBlue)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(DarkTheme.secondaryBackground)
            
            Divider().background(DarkTheme.borderSubtle)
            
            ScrollView([.horizontal, .vertical]) {
                Text(viewModel.response?.rawBodyString ?? "")
                    .font(AppTypography.code)
                    .foregroundColor(DarkTheme.textPrimary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }
}

public struct PreviewResponseView: View {
    @ObservedObject var viewModel: ResponseViewerViewModel
    
    public init(viewModel: ResponseViewerViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack {
            if let resp = viewModel.response {
                if resp.isImage, let nsImage = NSImage(data: resp.bodyData) {
                    ScrollView {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 800, maxHeight: 600)
                            .padding(24)
                    }
                } else if resp.isHTML {
                    // Safe sandboxed HTML text preview without executing scripts
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "shield.lefthalf.filled")
                                    .foregroundColor(DarkTheme.successGreen)
                                Text("HTML Response Preview (Scripts Disabled)")
                                    .font(AppTypography.captionMedium)
                                    .foregroundColor(DarkTheme.textSecondary)
                            }
                            .padding(.bottom, 8)
                            
                            Text(resp.rawBodyString)
                                .font(AppTypography.code)
                                .foregroundColor(DarkTheme.textPrimary)
                        }
                        .padding(16)
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "eye.slash")
                            .font(.system(size: 28))
                            .foregroundColor(DarkTheme.textMuted)
                        Text("No visual preview available for this Content-Type")
                            .font(AppTypography.body)
                            .foregroundColor(DarkTheme.textMuted)
                        Text("Switch to Pretty or Raw tab to view response data.")
                            .font(AppTypography.caption)
                            .foregroundColor(DarkTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
}

public struct ResponseHeadersView: View {
    @ObservedObject var viewModel: ResponseViewerViewModel
    
    public init(viewModel: ResponseViewerViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DarkTheme.textMuted)
                TextField("Filter headers...", text: $viewModel.headerFilterQuery)
                    .font(AppTypography.caption)
                    .foregroundColor(DarkTheme.textPrimary)
                    .textFieldStyle(.plain)
                Spacer()
                Text("\(viewModel.response?.headerList.count ?? 0) headers")
                    .font(AppTypography.caption)
                    .foregroundColor(DarkTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(DarkTheme.secondaryBackground)
            
            Divider().background(DarkTheme.borderSubtle)
            
            let headers = (viewModel.response?.headerList ?? []).filter {
                viewModel.headerFilterQuery.isEmpty ||
                $0.key.localizedCaseInsensitiveContains(viewModel.headerFilterQuery) ||
                $0.value.localizedCaseInsensitiveContains(viewModel.headerFilterQuery)
            }
            
            if headers.isEmpty {
                Text("No headers found")
                    .font(AppTypography.body)
                    .foregroundColor(DarkTheme.textMuted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(headers) { h in
                            HStack(alignment: .top, spacing: 12) {
                                Text(h.key)
                                    .font(AppTypography.codeBold)
                                    .foregroundColor(DarkTheme.primaryBlue)
                                    .frame(width: 200, alignment: .leading)
                                
                                Text(h.value)
                                    .font(AppTypography.code)
                                    .foregroundColor(DarkTheme.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Button(action: {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString("\(h.key): \(h.value)", forType: .string)
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 11))
                                        .foregroundColor(DarkTheme.textMuted)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            
                            Divider().background(DarkTheme.borderSubtle)
                        }
                    }
                }
            }
        }
    }
}

public struct ResponseCookiesView: View {
    @ObservedObject var viewModel: ResponseViewerViewModel
    
    public init(viewModel: ResponseViewerViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        let cookies = viewModel.response?.cookies ?? []
        if cookies.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "shield.slash")
                    .font(.system(size: 28))
                    .foregroundColor(DarkTheme.textMuted)
                Text("No cookies received in this response")
                    .font(AppTypography.body)
                    .foregroundColor(DarkTheme.textMuted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(cookies) { cookie in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(cookie.name)
                                    .font(AppTypography.codeBold)
                                    .foregroundColor(DarkTheme.primaryBlue)
                                Spacer()
                                if cookie.isSecure {
                                    Text("Secure")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(DarkTheme.successGreen)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(DarkTheme.successGreen.opacity(0.15))
                                        .cornerRadius(3)
                                }
                                if cookie.isHTTPOnly {
                                    Text("HTTPOnly")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(DarkTheme.warningYellow)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(DarkTheme.warningYellow.opacity(0.15))
                                        .cornerRadius(3)
                                }
                            }
                            
                            Text(cookie.value)
                                .font(AppTypography.code)
                                .foregroundColor(DarkTheme.textPrimary)
                            
                            HStack(spacing: 16) {
                                Text("Domain: \(cookie.domain)")
                                Text("Path: \(cookie.path)")
                                if let exp = cookie.expiresDate {
                                    Text("Expires: \(TimeFormatter.formatTimestamp(exp))")
                                }
                            }
                            .font(AppTypography.caption)
                            .foregroundColor(DarkTheme.textMuted)
                        }
                        .padding(16)
                        Divider().background(DarkTheme.borderSubtle)
                    }
                }
            }
        }
    }
}
