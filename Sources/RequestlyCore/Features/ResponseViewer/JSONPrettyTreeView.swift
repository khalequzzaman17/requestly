import SwiftUI

public struct JSONTreeNodeView: View {
    @ObservedObject var node: JSONTreeNode
    let searchQuery: String
    
    public init(node: JSONTreeNode, searchQuery: String = "") {
        self.node = node
        self.searchQuery = searchQuery
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                // Indentation
                if node.depth > 0 {
                    Spacer()
                        .frame(width: CGFloat(node.depth * 16))
                }
                
                // Expand / Collapse Chevron
                if node.nodeType.isExpandable {
                    Button(action: {
                        node.isExpanded.toggle()
                    }) {
                        Image(systemName: node.isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(DarkTheme.textSecondary)
                            .frame(width: 14, height: 14)
                    }
                    .buttonStyle(.plain)
                } else {
                    Spacer().frame(width: 14)
                }
                
                // Key (Blue)
                if let key = node.key {
                    Text("\"\(key)\"")
                        .font(AppTypography.codeBold)
                        .foregroundColor(DarkTheme.primaryBlue)
                    Text(":")
                        .font(AppTypography.code)
                        .foregroundColor(DarkTheme.textSecondary)
                }
                
                // Value Rendering with Syntax Colors
                switch node.nodeType {
                case .object(let count):
                    if node.isExpanded {
                        Text("{")
                            .font(AppTypography.code)
                            .foregroundColor(DarkTheme.textSecondary)
                    } else {
                        Text("{ \(count) \(count == 1 ? "item" : "items") }")
                            .font(AppTypography.codeSmall)
                            .foregroundColor(DarkTheme.textMuted)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(DarkTheme.elevatedBackground)
                            .cornerRadius(3)
                    }
                    
                case .array(let count):
                    if node.isExpanded {
                        Text("[")
                            .font(AppTypography.code)
                            .foregroundColor(DarkTheme.textSecondary)
                    } else {
                        Text("[ \(count) \(count == 1 ? "item" : "items") ]")
                            .font(AppTypography.codeSmall)
                            .foregroundColor(DarkTheme.textMuted)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(DarkTheme.elevatedBackground)
                            .cornerRadius(3)
                    }
                    
                case .string(let str):
                    Text("\"\(str)\"")
                        .font(AppTypography.code)
                        .foregroundColor(DarkTheme.successGreen)
                        .lineLimit(1)
                    
                case .number(let num):
                    Text(num)
                        .font(AppTypography.code)
                        .foregroundColor(DarkTheme.warningYellow)
                    
                case .boolean(let b):
                    Text(b ? "true" : "false")
                        .font(AppTypography.codeBold)
                        .foregroundColor(DarkTheme.accentPurple)
                    
                case .null:
                    Text("null")
                        .font(AppTypography.codeBold)
                        .foregroundColor(DarkTheme.errorRed)
                }
                
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if node.nodeType.isExpandable {
                    node.isExpanded.toggle()
                }
            }
            
            // Render Children if Expanded
            if node.isExpanded && !node.children.isEmpty {
                ForEach(node.children) { child in
                    if searchQuery.isEmpty || child.matchesSearch(searchQuery) {
                        JSONTreeNodeView(node: child, searchQuery: searchQuery)
                    }
                }
                
                // Closing bracket
                HStack {
                    if node.depth > 0 {
                        Spacer().frame(width: CGFloat(node.depth * 16))
                    }
                    Spacer().frame(width: 14)
                    
                    switch node.nodeType {
                    case .object:
                        Text("}")
                            .font(AppTypography.code)
                            .foregroundColor(DarkTheme.textSecondary)
                    case .array:
                        Text("]")
                            .font(AppTypography.code)
                            .foregroundColor(DarkTheme.textSecondary)
                    default:
                        EmptyView()
                    }
                }
            }
        }
    }
}

public struct JSONPrettyTreeView: View {
    @ObservedObject var viewModel: ResponseViewerViewModel
    
    public init(viewModel: ResponseViewerViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Sub-toolbar for Pretty JSON
            HStack(spacing: 12) {
                Picker("", selection: $viewModel.viewMode) {
                    Text("Tree").tag(0)
                    Text("Code").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
                
                if viewModel.viewMode == 0 {
                    Button(action: {
                        viewModel.expandAllJSON()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.right.and.arrow.up.left")
                            Text("Expand All")
                        }
                        .font(AppTypography.captionMedium)
                        .foregroundColor(DarkTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        viewModel.collapseAllJSON()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                            Text("Collapse All")
                        }
                        .font(AppTypography.captionMedium)
                        .foregroundColor(DarkTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.copyPrettyJSON()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy JSON")
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
            
            if let errorMsg = viewModel.jsonParsingError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(DarkTheme.warningYellow)
                    Text("Invalid JSON: \(errorMsg)")
                        .font(AppTypography.caption)
                        .foregroundColor(DarkTheme.warningYellow)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(DarkTheme.warningYellow.opacity(0.12))
            }
            
            // Content
            ScrollView([.horizontal, .vertical]) {
                if viewModel.viewMode == 0, let root = viewModel.jsonRootNode {
                    LazyVStack(alignment: .leading, spacing: 3) {
                        JSONTreeNodeView(node: root, searchQuery: viewModel.searchQuery)
                    }
                    .padding(16)
                } else {
                    // Formatted Code View with Line Numbers
                    HStack(alignment: .top, spacing: 12) {
                        let lines = viewModel.formattedJSON.components(separatedBy: "\n")
                        
                        // Line numbers
                        VStack(alignment: .trailing, spacing: 3) {
                            ForEach(1...max(1, lines.count), id: \.self) { num in
                                Text("\(num)")
                                    .font(AppTypography.code)
                                    .foregroundColor(DarkTheme.textMuted.opacity(0.6))
                            }
                        }
                        .frame(minWidth: 28, alignment: .trailing)
                        
                        Divider().background(DarkTheme.borderSubtle)
                        
                        // Formatted code
                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(0..<lines.count, id: \.self) { idx in
                                Text(lines[idx])
                                    .font(AppTypography.code)
                                    .foregroundColor(DarkTheme.textPrimary)
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
    }
}
