import SwiftUI
import AppKit

public final class ImportModalViewModel: ObservableObject {
    @Published public var importTab: Int = 0 // 0 = cURL, 1 = Postman
    @Published public var curlText: String = ""
    @Published public var postmanText: String = ""
    @Published public var errorMessage: String? = nil
    @Published public var successMessage: String? = nil
    
    public init() {}
}

public struct ImportModalView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = ImportModalViewModel()
    
    public var onImportRequest: ((HTTPRequestModel) -> Void)? = nil
    public var onImportFinished: (() -> Void)? = nil
    
    public init(
        onImportRequest: ((HTTPRequestModel) -> Void)? = nil,
        onImportFinished: (() -> Void)? = nil
    ) {
        self.onImportRequest = onImportRequest
        self.onImportFinished = onImportFinished
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Import")
                    .font(AppTypography.headline)
                    .foregroundColor(DarkTheme.textPrimary)
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Text("Close")
                        .font(AppTypography.captionMedium)
                        .foregroundColor(DarkTheme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(DarkTheme.elevatedBackground)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(DarkTheme.sidebarBackground)
            
            Divider().background(DarkTheme.borderDefault)
            
            // Tab Picker
            Picker("", selection: $vm.importTab) {
                Text("cURL Command").tag(0)
                Text("Postman Collection").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(16)
            
            if let err = vm.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(DarkTheme.errorRed)
                    Text(err)
                        .font(AppTypography.caption)
                        .foregroundColor(DarkTheme.errorRed)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background(DarkTheme.errorRed.opacity(0.12))
            }
            
            if let succ = vm.successMessage {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DarkTheme.successGreen)
                    Text(succ)
                        .font(AppTypography.caption)
                        .foregroundColor(DarkTheme.successGreen)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background(DarkTheme.successGreen.opacity(0.12))
            }
            
            if vm.importTab == 0 {
                // cURL Tab
                VStack(alignment: .leading, spacing: 8) {
                    Text("Paste raw cURL command:")
                        .font(AppTypography.captionMedium)
                        .foregroundColor(DarkTheme.textSecondary)
                        .padding(.horizontal, 16)
                    
                    TextEditor(text: $vm.curlText)
                        .font(AppTypography.code)
                        .foregroundColor(DarkTheme.textPrimary)
                        .scrollContentBackground(.hidden)
                        .background(DarkTheme.editorBackground)
                        .cornerRadius(6)
                        .padding(.horizontal, 16)
                    
                    HStack {
                        Button("Paste Sample cURL") {
                            vm.curlText = "curl -X POST 'https://httpbin.org/post' \\\n  -H 'Content-Type: application/json' \\\n  -H 'Authorization: Bearer test_token_123' \\\n  -d '{\"hello\": \"world\", \"client\": \"Requestly\"}'"
                        }
                        .font(AppTypography.caption)
                        .foregroundColor(DarkTheme.textMuted)
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button("Import to Editor") {
                            importCurl()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(DarkTheme.primaryBlue)
                        .cornerRadius(6)
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                }
            } else {
                // Postman Collection Tab
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Paste Postman Collection JSON or choose file:")
                            .font(AppTypography.captionMedium)
                            .foregroundColor(DarkTheme.textSecondary)
                        Spacer()
                        Button("Choose File...") {
                            choosePostmanFile()
                        }
                        .font(AppTypography.captionMedium)
                        .foregroundColor(DarkTheme.primaryBlue)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    
                    TextEditor(text: $vm.postmanText)
                        .font(AppTypography.code)
                        .foregroundColor(DarkTheme.textPrimary)
                        .scrollContentBackground(.hidden)
                        .background(DarkTheme.editorBackground)
                        .cornerRadius(6)
                        .padding(.horizontal, 16)
                    
                    HStack {
                        Spacer()
                        Button("Import Collection") {
                            importPostman()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(DarkTheme.primaryBlue)
                        .cornerRadius(6)
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                }
            }
        }
        .frame(width: 600, height: 420)
        .background(DarkTheme.mainBackground)
        .forceDarkMode()
    }
    
    private func importCurl() {
        vm.errorMessage = nil
        do {
            let req = try CurlParserAndExporter.shared.parse(curlCommand: vm.curlText)
            onImportRequest?(req)
            dismiss()
        } catch {
            vm.errorMessage = error.localizedDescription
        }
    }
    
    private func importPostman() {
        vm.errorMessage = nil
        guard let data = vm.postmanText.data(using: .utf8) else {
            vm.errorMessage = "Invalid JSON data."
            return
        }
        do {
            let result = try PostmanCollectionParser.shared.parse(data: data)
            try DatabaseService.shared.saveCollection(result.collection)
            for folder in result.folders {
                try DatabaseService.shared.saveFolder(folder)
            }
            for req in result.requests {
                try DatabaseService.shared.saveRequest(req)
            }
            vm.successMessage = "Successfully imported collection '\(result.collection.name)' with \(result.requests.count) requests!"
            onImportFinished?()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dismiss()
            }
        } catch {
            vm.errorMessage = "Failed to parse Postman collection: \(error.localizedDescription)"
        }
    }
    
    private func choosePostmanFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url, let content = try? String(contentsOf: url) {
            self.vm.postmanText = content
        }
    }
}
