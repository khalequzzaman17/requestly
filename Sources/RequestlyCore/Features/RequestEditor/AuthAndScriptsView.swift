import SwiftUI

public struct AuthEditorView: View {
    @ObservedObject var viewModel: RequestEditorViewModel
    
    public init(viewModel: RequestEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Authentication Type")
                    .font(AppTypography.captionMedium)
                    .foregroundColor(DarkTheme.textSecondary)
                
                Picker("", selection: $viewModel.request.auth.type) {
                    ForEach(AuthType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 180)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            Divider().background(DarkTheme.borderSubtle)
            
            VStack(alignment: .leading, spacing: 12) {
                switch viewModel.request.auth.type {
                case .none:
                    Text("This request does not use any authentication.")
                        .font(AppTypography.body)
                        .foregroundColor(DarkTheme.textMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                    
                case .bearer:
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Token")
                            .font(AppTypography.captionMedium)
                            .foregroundColor(DarkTheme.textSecondary)
                        SecureField("Bearer token...", text: $viewModel.request.auth.bearerToken)
                            .font(AppTypography.code)
                            .foregroundColor(DarkTheme.textPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(DarkTheme.editorBackground)
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(DarkTheme.borderDefault, lineWidth: 1))
                            .textFieldStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    
                case .basic:
                    VStack(alignment: .leading, spacing: 10) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Username")
                                .font(AppTypography.captionMedium)
                                .foregroundColor(DarkTheme.textSecondary)
                            DarkTextField(placeholder: "Username", text: $viewModel.request.auth.basicUsername)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(AppTypography.captionMedium)
                                .foregroundColor(DarkTheme.textSecondary)
                            SecureField("Password", text: $viewModel.request.auth.basicPassword)
                                .font(AppTypography.code)
                                .foregroundColor(DarkTheme.textPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(DarkTheme.editorBackground)
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(DarkTheme.borderDefault, lineWidth: 1))
                                .textFieldStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                case .apiKey:
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Key Name")
                                    .font(AppTypography.captionMedium)
                                    .foregroundColor(DarkTheme.textSecondary)
                                DarkTextField(placeholder: "X-API-Key", text: $viewModel.request.auth.apiKeyName, isMonospaced: true)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Add To")
                                    .font(AppTypography.captionMedium)
                                    .foregroundColor(DarkTheme.textSecondary)
                                Picker("", selection: $viewModel.request.auth.apiKeyLocation) {
                                    Text("Header").tag(APIKeyLocation.header)
                                    Text("Query Param").tag(APIKeyLocation.queryParam)
                                }
                                .pickerStyle(.segmented)
                            }
                            .frame(width: 180)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Value")
                                .font(AppTypography.captionMedium)
                                .foregroundColor(DarkTheme.textSecondary)
                            SecureField("API Key value...", text: $viewModel.request.auth.apiKeyValue)
                                .font(AppTypography.code)
                                .foregroundColor(DarkTheme.textPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(DarkTheme.editorBackground)
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(DarkTheme.borderDefault, lineWidth: 1))
                                .textFieldStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                case .oauth2:
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Access Token")
                            .font(AppTypography.captionMedium)
                            .foregroundColor(DarkTheme.textSecondary)
                        SecureField("Access token...", text: $viewModel.request.auth.oauthToken)
                            .font(AppTypography.code)
                            .foregroundColor(DarkTheme.textPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(DarkTheme.editorBackground)
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(DarkTheme.borderDefault, lineWidth: 1))
                            .textFieldStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                }
            }
            Spacer()
        }
    }
}

public struct ScriptsEditorView: View {
    @ObservedObject var viewModel: RequestEditorViewModel
    
    public init(viewModel: RequestEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("", selection: $viewModel.scriptTab) {
                Text("Pre-request Script").tag(0)
                Text("Post-response Tests").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            if viewModel.scriptTab == 0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Executed prior to sending the request")
                        .font(AppTypography.caption)
                        .foregroundColor(DarkTheme.textMuted)
                        .padding(.horizontal, 16)
                    TextEditor(text: $viewModel.request.preRequestScript)
                        .font(AppTypography.code)
                        .foregroundColor(DarkTheme.textPrimary)
                        .scrollContentBackground(.hidden)
                        .background(DarkTheme.editorBackground)
                        .cornerRadius(6)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Executed after receiving the response")
                        .font(AppTypography.caption)
                        .foregroundColor(DarkTheme.textMuted)
                        .padding(.horizontal, 16)
                    TextEditor(text: $viewModel.request.postResponseScript)
                        .font(AppTypography.code)
                        .foregroundColor(DarkTheme.textPrimary)
                        .scrollContentBackground(.hidden)
                        .background(DarkTheme.editorBackground)
                        .cornerRadius(6)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
            }
        }
    }
}
