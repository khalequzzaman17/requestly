import SwiftUI

public struct MethodBadgeView: View {
    public let method: String
    public var fontSize: CGFloat = 10
    
    public init(method: String, fontSize: CGFloat = 10) {
        self.method = method
        self.fontSize = fontSize
    }
    
    public var body: some View {
        Text(method.uppercased())
            .font(.system(size: fontSize, weight: .bold, design: .monospaced))
            .foregroundColor(MethodColor.color(for: method))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(MethodColor.background(for: method))
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(MethodColor.color(for: method).opacity(0.3), lineWidth: 1)
            )
    }
}

public struct StatusBadgeView: View {
    public let statusCode: Int
    public let statusDescription: String
    
    public init(statusCode: Int, statusDescription: String) {
        self.statusCode = statusCode
        self.statusDescription = statusDescription
    }
    
    private var statusColor: Color {
        switch statusCode {
        case 200..<300:
            return DarkTheme.successGreen
        case 300..<400:
            return DarkTheme.primaryBlue
        case 400..<500:
            return DarkTheme.warningYellow
        case 500..<600:
            return DarkTheme.errorRed
        default:
            return DarkTheme.textSecondary
        }
    }
    
    public var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
            Text("\(statusCode) \(statusDescription)")
                .font(AppTypography.captionMedium)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.12))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(statusColor.opacity(0.25), lineWidth: 1)
        )
    }
}

public struct DarkTextField: View {
    public let placeholder: String
    @Binding public var text: String
    public var isMonospaced: Bool = false
    public var onCommit: (() -> Void)? = nil
    
    public init(placeholder: String, text: Binding<String>, isMonospaced: Bool = false, onCommit: (() -> Void)? = nil) {
        self.placeholder = placeholder
        self._text = text
        self.isMonospaced = isMonospaced
        self.onCommit = onCommit
    }
    
    public var body: some View {
        TextField(
            "",
            text: $text,
            prompt: Text(placeholder).foregroundColor(DarkTheme.textMuted)
        )
        .onSubmit {
            onCommit?()
        }
        .font(isMonospaced ? AppTypography.code : AppTypography.body)
        .foregroundColor(DarkTheme.textPrimary)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(DarkTheme.editorBackground)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(DarkTheme.borderDefault, lineWidth: 1)
        )
        .textFieldStyle(.plain)
    }
}

public struct KeyValueRowView: View {
    @Binding public var item: KeyValueItem
    public var onDelete: () -> Void
    public var keyPlaceholder: String = "Key"
    public var valuePlaceholder: String = "Value"
    
    public init(
        item: Binding<KeyValueItem>,
        keyPlaceholder: String = "Key",
        valuePlaceholder: String = "Value",
        onDelete: @escaping () -> Void
    ) {
        self._item = item
        self.keyPlaceholder = keyPlaceholder
        self.valuePlaceholder = valuePlaceholder
        self.onDelete = onDelete
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            Toggle("", isOn: $item.isEnabled)
                .toggleStyle(.checkbox)
                .labelsHidden()
            
            DarkTextField(placeholder: keyPlaceholder, text: $item.key, isMonospaced: true)
                .frame(maxWidth: .infinity)
            
            DarkTextField(placeholder: valuePlaceholder, text: $item.value, isMonospaced: true)
                .frame(maxWidth: .infinity)
            
            DarkTextField(placeholder: "Description", text: $item.description)
                .frame(maxWidth: 180)
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(DarkTheme.textMuted)
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 2)
    }
}
