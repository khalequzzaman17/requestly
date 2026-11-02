import SwiftUI

public struct RequestEditorView: View {
    @ObservedObject var viewModel: RequestEditorViewModel
    
    public init(viewModel: RequestEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Request Bar: Method Selector + URL Bar + Send/Cancel Button + Save
            HStack(spacing: 8) {
                // Method Picker Menu
                Menu {
                    ForEach(HTTPMethod.allCases) { method in
                        Button(action: {
                            viewModel.request.method = method
                        }) {
                            Text(method.rawValue)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.request.method.rawValue)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(MethodColor.color(for: viewModel.request.method.rawValue))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(DarkTheme.textSecondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(DarkTheme.secondaryBackground)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(DarkTheme.borderDefault, lineWidth: 1)
                    )
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                
                // URL input bar
                HStack {
                    TextField(
                        "Enter request URL (e.g. https://api.example.com/v1/users)...",
                        text: $viewModel.request.url
                    )
                    .onSubmit {
                        viewModel.onExecute?()
                    }
                    .font(AppTypography.code)
                    .foregroundColor(DarkTheme.textPrimary)
                    .textFieldStyle(.plain)
                    .onChange(of: viewModel.request.url) { _ in
                        viewModel.updateParamsFromURL()
                    }
                    
                    if !viewModel.request.url.isEmpty {
                        Button(action: {
                            viewModel.request.url = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(DarkTheme.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(DarkTheme.editorBackground)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(DarkTheme.borderDefault, lineWidth: 1)
                )
                
                // Send / Cancel Action Button
                if viewModel.isExecuting {
                    Button(action: {
                        viewModel.onCancel?()
                    }) {
                        HStack(spacing: 6) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Cancel")
                                .font(AppTypography.bodyMedium)
                        }
                        .foregroundColor(DarkTheme.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(DarkTheme.errorRed)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: {
                        viewModel.onExecute?()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 11))
                            Text("Send")
                                .font(AppTypography.bodyMedium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(DarkTheme.primaryBlue)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.return, modifiers: [.command])
                }
                
                // Save Button
                Button(action: {
                    viewModel.onSave?()
                }) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 13))
                        .foregroundColor(DarkTheme.textSecondary)
                        .padding(7)
                        .background(DarkTheme.secondaryBackground)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(DarkTheme.borderDefault, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .help("Save Request (⌘S)")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(DarkTheme.mainBackground)
            
            Divider()
                .background(DarkTheme.borderDefault)
            
            // Configuration Tab Bar (Params, Headers, Body, Auth, Scripts)
            HStack(spacing: 2) {
                ForEach(RequestConfigTab.allCases) { tab in
                    Button(action: {
                        viewModel.activeConfigTab = tab
                    }) {
                        HStack(spacing: 4) {
                            Text(tab.rawValue)
                                .font(AppTypography.captionMedium)
                            
                            // Badge indicators
                            switch tab {
                            case .params:
                                let count = viewModel.request.queryParams.filter { $0.isEnabled && !$0.key.isEmpty }.count
                                if count > 0 {
                                    Text("\(count)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(DarkTheme.primaryBlue)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(DarkTheme.primaryBlue.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            case .headers:
                                let count = viewModel.request.headers.filter { $0.isEnabled && !$0.key.isEmpty }.count
                                if count > 0 {
                                    Text("\(count)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(DarkTheme.textSecondary)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(DarkTheme.elevatedBackground)
                                        .clipShape(Capsule())
                                }
                            case .body:
                                if viewModel.request.bodyType != .none {
                                    Circle()
                                        .fill(DarkTheme.primaryBlue)
                                        .frame(width: 5, height: 5)
                                }
                            case .auth:
                                if viewModel.request.auth.type != .none {
                                    Circle()
                                        .fill(DarkTheme.successGreen)
                                        .frame(width: 5, height: 5)
                                }
                            case .scripts:
                                if !viewModel.request.preRequestScript.isEmpty || !viewModel.request.postResponseScript.isEmpty {
                                    Circle()
                                        .fill(DarkTheme.warningYellow)
                                        .frame(width: 5, height: 5)
                                }
                            }
                        }
                        .foregroundColor(viewModel.activeConfigTab == tab ? DarkTheme.textPrimary : DarkTheme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(viewModel.activeConfigTab == tab ? DarkTheme.editorBackground : Color.clear)
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(DarkTheme.mainBackground)
            
            Divider()
                .background(DarkTheme.borderSubtle)
            
            // Tab Content
            ZStack {
                DarkTheme.editorBackground.ignoresSafeArea()
                
                switch viewModel.activeConfigTab {
                case .params:
                    ParamsEditorView(viewModel: viewModel)
                case .headers:
                    HeadersEditorView(viewModel: viewModel)
                case .body:
                    BodyEditorView(viewModel: viewModel)
                case .auth:
                    AuthEditorView(viewModel: viewModel)
                case .scripts:
                    ScriptsEditorView(viewModel: viewModel)
                }
            }
        }
    }
}
