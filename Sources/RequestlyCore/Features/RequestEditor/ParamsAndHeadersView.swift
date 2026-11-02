import SwiftUI

public struct ParamsEditorView: View {
    @ObservedObject var viewModel: RequestEditorViewModel
    
    public init(viewModel: RequestEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Query Parameters")
                    .font(AppTypography.captionMedium)
                    .foregroundColor(DarkTheme.textSecondary)
                Spacer()
                Button(action: {
                    viewModel.addParam()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add Parameter")
                    }
                    .font(AppTypography.captionMedium)
                    .foregroundColor(DarkTheme.primaryBlue)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            if viewModel.request.queryParams.isEmpty {
                VStack(spacing: 8) {
                    Text("No query parameters configured")
                        .font(AppTypography.body)
                        .foregroundColor(DarkTheme.textMuted)
                    Button("Add Parameter") {
                        viewModel.addParam()
                    }
                    .font(AppTypography.captionMedium)
                    .foregroundColor(DarkTheme.primaryBlue)
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach($viewModel.request.queryParams) { $item in
                            KeyValueRowView(
                                item: $item,
                                keyPlaceholder: "Parameter",
                                valuePlaceholder: "Value",
                                onDelete: {
                                    if let idx = viewModel.request.queryParams.firstIndex(where: { $0.id == item.id }) {
                                        viewModel.request.queryParams.remove(at: idx)
                                        viewModel.updateURLFromParams()
                                    }
                                }
                            )
                            .onChange(of: item) { _ in
                                viewModel.updateURLFromParams()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
    }
}

public struct HeadersEditorView: View {
    @ObservedObject var viewModel: RequestEditorViewModel
    
    public init(viewModel: RequestEditorViewModel) {
        self.viewModel = viewModel
    }
    
    private let commonHeaders = [
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer ",
        "User-Agent": "Requestly/1.0",
        "Cache-Control": "no-cache"
    ]
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("HTTP Headers")
                    .font(AppTypography.captionMedium)
                    .foregroundColor(DarkTheme.textSecondary)
                Spacer()
                
                // Quick add common headers menu
                Menu {
                    ForEach(commonHeaders.keys.sorted(), id: \.self) { key in
                        Button(key) {
                            let val = commonHeaders[key] ?? ""
                            viewModel.request.headers.append(
                                KeyValueItem(key: key, value: val, description: "", isEnabled: true)
                            )
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("Add Common Header")
                    }
                    .font(AppTypography.captionMedium)
                    .foregroundColor(DarkTheme.textSecondary)
                }
                .menuStyle(.borderlessButton)
                
                Button(action: {
                    viewModel.addHeader()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add Header")
                    }
                    .font(AppTypography.captionMedium)
                    .foregroundColor(DarkTheme.primaryBlue)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            if viewModel.request.headers.isEmpty {
                VStack(spacing: 8) {
                    Text("No headers configured")
                        .font(AppTypography.body)
                        .foregroundColor(DarkTheme.textMuted)
                    Button("Add Header") {
                        viewModel.addHeader()
                    }
                    .font(AppTypography.captionMedium)
                    .foregroundColor(DarkTheme.primaryBlue)
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach($viewModel.request.headers) { $item in
                            KeyValueRowView(
                                item: $item,
                                keyPlaceholder: "Header",
                                valuePlaceholder: "Value",
                                onDelete: {
                                    if let idx = viewModel.request.headers.firstIndex(where: { $0.id == item.id }) {
                                        viewModel.request.headers.remove(at: idx)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
    }
}
