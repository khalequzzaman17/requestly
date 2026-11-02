import SwiftUI

@MainActor
public final class EnvironmentViewModel: ObservableObject {
    @Published public var environments: [EnvironmentModel] = []
    @Published public var selectedEnvironment: EnvironmentModel?
    @Published public var newEnvironmentName: String = ""
    @Published public var showNewEnvAlert: Bool = false
    
    private let databaseService: DatabaseServiceProtocol
    
    public init(databaseService: DatabaseServiceProtocol = DatabaseService.shared) {
        self.databaseService = databaseService
        loadEnvironments()
    }
    
    public func loadEnvironments() {
        if let envs = try? databaseService.fetchEnvironments() {
            self.environments = envs
            if selectedEnvironment == nil {
                self.selectedEnvironment = envs.first(where: { $0.isSelected }) ?? envs.first
            }
        }
        if environments.isEmpty {
            // Seed default environments
            let dev = EnvironmentModel(name: "Development", variables: [
                EnvironmentVariable(key: "base_url", value: "https://httpbin.org", isSecret: false),
                EnvironmentVariable(key: "api_key", value: "dev_secret_key_123", isSecret: true)
            ], isSelected: true)
            let prod = EnvironmentModel(name: "Production", variables: [
                EnvironmentVariable(key: "base_url", value: "https://api.example.com", isSecret: false),
                EnvironmentVariable(key: "api_key", value: "prod_live_key_xyz", isSecret: true)
            ], isSelected: false)
            try? databaseService.saveEnvironment(dev)
            try? databaseService.saveEnvironment(prod)
            self.environments = [dev, prod]
            self.selectedEnvironment = dev
        }
    }
    
    public func createEnvironment(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let env = EnvironmentModel(name: trimmed, variables: [])
        try? databaseService.saveEnvironment(env)
        loadEnvironments()
        self.selectedEnvironment = env
    }
    
    public func saveSelectedEnvironment() {
        guard let env = selectedEnvironment else { return }
        try? databaseService.saveEnvironment(env)
        loadEnvironments()
    }
    
    public func deleteSelectedEnvironment() {
        guard let env = selectedEnvironment else { return }
        try? databaseService.deleteEnvironment(id: env.id)
        selectedEnvironment = nil
        loadEnvironments()
    }
    
    public func setActiveEnvironment(_ env: EnvironmentModel) {
        for var e in environments {
            e.isSelected = (e.id == env.id)
            try? databaseService.saveEnvironment(e)
        }
        loadEnvironments()
    }
    
    public func addVariable() {
        guard var env = selectedEnvironment else { return }
        env.variables.append(EnvironmentVariable(key: "variable_name", value: "value"))
        self.selectedEnvironment = env
        saveSelectedEnvironment()
    }
}

public struct EnvironmentManagerView: View {
    @ObservedObject var viewModel: EnvironmentViewModel
    @Environment(\.dismiss) private var dismiss
    
    public init(viewModel: EnvironmentViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Manage Environments")
                    .font(AppTypography.headline)
                    .foregroundColor(DarkTheme.textPrimary)
                Spacer()
                Button(action: {
                    viewModel.saveSelectedEnvironment()
                    dismiss()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                        Text("Done")
                            .font(AppTypography.captionMedium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(DarkTheme.primaryBlue)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .focusable(false)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(DarkTheme.sidebarBackground)
            
            Divider().background(DarkTheme.borderDefault)
            
            HSplitView {
                // Left pane: Environments list
                VStack(spacing: 0) {
                    HStack {
                        Text("ENVIRONMENTS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(DarkTheme.textMuted)
                        Spacer()
                        Button(action: {
                            viewModel.showNewEnvAlert = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 11))
                                .foregroundColor(DarkTheme.primaryBlue)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    
                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(viewModel.environments) { env in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(env.name)
                                                .font(AppTypography.bodyMedium)
                                                .foregroundColor(viewModel.selectedEnvironment?.id == env.id ? DarkTheme.textPrimary : DarkTheme.textSecondary)
                                            if env.isSelected {
                                                Circle()
                                                    .fill(DarkTheme.successGreen)
                                                    .frame(width: 6, height: 6)
                                            }
                                        }
                                        Text("\(env.variables.count) variables")
                                            .font(AppTypography.caption)
                                            .foregroundColor(DarkTheme.textMuted)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(viewModel.selectedEnvironment?.id == env.id ? DarkTheme.secondaryBackground : Color.clear)
                                .cornerRadius(6)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.selectedEnvironment = env
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                }
                .frame(width: 200)
                .background(DarkTheme.sidebarBackground)
                
                // Right pane: Environment variables editor
                VStack(spacing: 0) {
                    if let selected = viewModel.selectedEnvironment {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(selected.name)
                                    .font(AppTypography.headline)
                                    .foregroundColor(DarkTheme.textPrimary)
                                Text("Use {{variable}} syntax in requests to inject values.")
                                    .font(AppTypography.caption)
                                    .foregroundColor(DarkTheme.textMuted)
                            }
                            Spacer()
                            if !selected.isSelected {
                                Button("Set as Active") {
                                    viewModel.setActiveEnvironment(selected)
                                }
                                .font(AppTypography.captionMedium)
                                .foregroundColor(DarkTheme.successGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(DarkTheme.successGreen.opacity(0.12))
                                .cornerRadius(4)
                                .buttonStyle(.plain)
                            }
                            Button("Add Variable") {
                                viewModel.addVariable()
                            }
                            .font(AppTypography.captionMedium)
                            .foregroundColor(DarkTheme.primaryBlue)
                            .buttonStyle(.plain)
                        }
                        .padding(16)
                        
                        Divider().background(DarkTheme.borderSubtle)
                        
                        // Variables Table
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(bindingForVariables()) { $item in
                                    HStack(spacing: 8) {
                                        Toggle("", isOn: $item.isEnabled)
                                            .toggleStyle(.checkbox)
                                            .labelsHidden()
                                        
                                        DarkTextField(placeholder: "Variable", text: $item.key, isMonospaced: true)
                                            .frame(maxWidth: .infinity)
                                        
                                        if item.isSecret {
                                            SecureField("Value", text: $item.value)
                                                .font(AppTypography.code)
                                                .foregroundColor(DarkTheme.textPrimary)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 6)
                                                .background(DarkTheme.editorBackground)
                                                .cornerRadius(6)
                                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(DarkTheme.borderDefault, lineWidth: 1))
                                                .textFieldStyle(.plain)
                                                .frame(maxWidth: .infinity)
                                        } else {
                                            DarkTextField(placeholder: "Value", text: $item.value, isMonospaced: true)
                                                .frame(maxWidth: .infinity)
                                        }
                                        
                                        Button(action: {
                                            item.isSecret.toggle()
                                        }) {
                                            Image(systemName: item.isSecret ? "eye.slash" : "eye")
                                                .foregroundColor(item.isSecret ? DarkTheme.warningYellow : DarkTheme.textMuted)
                                                .font(.system(size: 11))
                                        }
                                        .buttonStyle(.plain)
                                        .help(item.isSecret ? "Masked Secret" : "Plain Value")
                                        
                                        Button(action: {
                                            if let idx = viewModel.selectedEnvironment?.variables.firstIndex(where: { $0.id == item.id }) {
                                                viewModel.selectedEnvironment?.variables.remove(at: idx)
                                                viewModel.saveSelectedEnvironment()
                                            }
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(DarkTheme.textMuted)
                                                .font(.system(size: 11))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                            .padding(.vertical, 12)
                        }
                    } else {
                        Text("Select or create an environment")
                            .font(AppTypography.body)
                            .foregroundColor(DarkTheme.textMuted)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .background(DarkTheme.editorBackground)
            }
        }
        .frame(width: 700, height: 480)
        .background(DarkTheme.mainBackground)
        .forceDarkMode()
        .sheet(isPresented: $viewModel.showNewEnvAlert) {
            VStack(spacing: 14) {
                Text("New Environment")
                    .font(AppTypography.headline)
                    .foregroundColor(DarkTheme.textPrimary)
                DarkTextField(placeholder: "Environment Name (e.g. Staging)", text: $viewModel.newEnvironmentName)
                    .frame(width: 260)
                HStack(spacing: 12) {
                    Button("Cancel") {
                        viewModel.showNewEnvAlert = false
                    }
                    .foregroundColor(DarkTheme.textSecondary)
                    Button("Create") {
                        viewModel.createEnvironment(name: viewModel.newEnvironmentName)
                        viewModel.showNewEnvAlert = false
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
    
    private func bindingForVariables() -> Binding<[EnvironmentVariable]> {
        Binding(
            get: { viewModel.selectedEnvironment?.variables ?? [] },
            set: {
                viewModel.selectedEnvironment?.variables = $0
                viewModel.saveSelectedEnvironment()
            }
        )
    }
}
