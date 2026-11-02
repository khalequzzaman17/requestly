import SwiftUI
import AppKit

public struct BodyEditorView: View {
    @ObservedObject var viewModel: RequestEditorViewModel
    
    public init(viewModel: RequestEditorViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Body type selector
            HStack(spacing: 8) {
                ForEach(RequestBodyType.allCases) { type in
                    Button(action: {
                        viewModel.request.bodyType = type
                    }) {
                        Text(type.rawValue)
                            .font(AppTypography.captionMedium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(viewModel.request.bodyType == type ? DarkTheme.elevatedBackground : Color.clear)
                            .foregroundColor(viewModel.request.bodyType == type ? DarkTheme.textPrimary : DarkTheme.textSecondary)
                            .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                if viewModel.request.bodyType == .json {
                    Button(action: {
                        viewModel.formatJSONBody()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "wand.and.stars")
                            Text("Format")
                        }
                        .font(AppTypography.captionMedium)
                        .foregroundColor(DarkTheme.primaryBlue)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        viewModel.minifyJSONBody()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.right.and.line.vertical.and.arrow.left")
                            Text("Minify")
                        }
                        .font(AppTypography.captionMedium)
                        .foregroundColor(DarkTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            
            Divider()
                .background(DarkTheme.borderSubtle)
            
            // Body content area
            switch viewModel.request.bodyType {
            case .none:
                VStack(spacing: 6) {
                    Text("This request does not have a body")
                        .font(AppTypography.body)
                        .foregroundColor(DarkTheme.textMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            case .json:
                VStack(alignment: .leading, spacing: 4) {
                    if let err = viewModel.jsonValidationError {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(DarkTheme.warningYellow)
                            Text(err)
                                .font(AppTypography.caption)
                                .foregroundColor(DarkTheme.warningYellow)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                        .background(DarkTheme.warningYellow.opacity(0.1))
                        .cornerRadius(4)
                        .padding(.horizontal, 16)
                    }
                    
                    TextEditor(text: $viewModel.request.rawBodyText)
                        .font(AppTypography.code)
                        .foregroundColor(DarkTheme.textPrimary)
                        .scrollContentBackground(.hidden)
                        .background(DarkTheme.editorBackground)
                        .cornerRadius(6)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
                
            case .text:
                TextEditor(text: $viewModel.request.rawBodyText)
                    .font(AppTypography.code)
                    .foregroundColor(DarkTheme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .background(DarkTheme.editorBackground)
                    .cornerRadius(6)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                
            case .urlEncoded:
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.addUrlEncodedItem()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Add Field")
                            }
                            .font(AppTypography.captionMedium)
                            .foregroundColor(DarkTheme.primaryBlue)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    
                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach($viewModel.request.urlEncodedItems) { $item in
                                KeyValueRowView(
                                    item: $item,
                                    keyPlaceholder: "Field Name",
                                    valuePlaceholder: "Field Value",
                                    onDelete: {
                                        if let idx = viewModel.request.urlEncodedItems.firstIndex(where: { $0.id == item.id }) {
                                            viewModel.request.urlEncodedItems.remove(at: idx)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                
            case .formData:
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.addFormDataItem()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Add Field")
                            }
                            .font(AppTypography.captionMedium)
                            .foregroundColor(DarkTheme.primaryBlue)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    
                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach($viewModel.request.formDataItems) { $item in
                                HStack(spacing: 8) {
                                    Toggle("", isOn: $item.isEnabled)
                                        .toggleStyle(.checkbox)
                                        .labelsHidden()
                                    
                                    DarkTextField(placeholder: "Field", text: $item.key, isMonospaced: true)
                                        .frame(maxWidth: .infinity)
                                    
                                    Picker("", selection: $item.isFile) {
                                        Text("Text").tag(false)
                                        Text("File").tag(true)
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 100)
                                    
                                    if item.isFile {
                                        HStack {
                                            Text(item.filePath.map { URL(fileURLWithPath: $0).lastPathComponent } ?? "Choose file...")
                                                .font(AppTypography.caption)
                                                .foregroundColor(item.filePath != nil ? DarkTheme.textPrimary : DarkTheme.textMuted)
                                                .lineLimit(1)
                                            Spacer()
                                            Button("Browse") {
                                                selectFile { path in
                                                    item.filePath = path
                                                }
                                            }
                                            .font(AppTypography.caption)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 5)
                                        .background(DarkTheme.editorBackground)
                                        .cornerRadius(6)
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(DarkTheme.borderDefault, lineWidth: 1))
                                        .frame(maxWidth: .infinity)
                                    } else {
                                        DarkTextField(placeholder: "Value", text: $item.value)
                                            .frame(maxWidth: .infinity)
                                    }
                                    
                                    Button(action: {
                                        if let idx = viewModel.request.formDataItems.firstIndex(where: { $0.id == item.id }) {
                                            viewModel.request.formDataItems.remove(at: idx)
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(DarkTheme.textMuted)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                
            case .binary:
                VStack(spacing: 12) {
                    if let path = viewModel.request.binaryFilePath {
                        HStack(spacing: 10) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 24))
                                .foregroundColor(DarkTheme.primaryBlue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(URL(fileURLWithPath: path).lastPathComponent)
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(DarkTheme.textPrimary)
                                Text(path)
                                    .font(AppTypography.caption)
                                    .foregroundColor(DarkTheme.textMuted)
                            }
                            Spacer()
                            Button("Remove") {
                                viewModel.request.binaryFilePath = nil
                            }
                            .foregroundColor(DarkTheme.errorRed)
                            .buttonStyle(.plain)
                        }
                        .padding(12)
                        .background(DarkTheme.secondaryBackground)
                        .cornerRadius(8)
                        .padding(.horizontal, 16)
                    } else {
                        Button(action: {
                            selectFile { path in
                                viewModel.request.binaryFilePath = path
                            }
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "arrow.up.doc")
                                    .font(.system(size: 28))
                                    .foregroundColor(DarkTheme.primaryBlue)
                                Text("Choose File to Upload")
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(DarkTheme.textPrimary)
                                Text("Select a local file to send as binary request body")
                                    .font(AppTypography.caption)
                                    .foregroundColor(DarkTheme.textMuted)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(DarkTheme.editorBackground)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(DarkTheme.borderDefault, style: StrokeStyle(lineWidth: 1, dash: [4]))
                            )
                            .padding(16)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private func selectFile(completion: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            completion(url.path)
        }
    }
}
