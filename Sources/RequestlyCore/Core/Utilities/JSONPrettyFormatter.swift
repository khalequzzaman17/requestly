import Foundation

public enum JSONFormatterError: LocalizedError {
    case invalidData
    case parsingFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Unable to decode data as UTF-8 string."
        case .parsingFailed(let reason):
            return "JSON parsing error: \(reason)"
        }
    }
}

public final class JSONPrettyFormatter {
    public static let shared = JSONPrettyFormatter()
    
    public init() {}
    
    /// Pretty-print JSON Data with configurable indentation (default: 2 spaces).
    public func prettyPrint(data: Data, indentSpaces: Int = 2) -> Result<String, JSONFormatterError> {
        guard !data.isEmpty else {
            return .success("")
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            let formattedData = try JSONSerialization.data(
                withJSONObject: jsonObject,
                options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            )
            
            guard var formattedString = String(data: formattedData, encoding: .utf8) else {
                return .failure(.invalidData)
            }
            
            // Adjust indentation if different from standard 4 spaces
            if indentSpaces != 4 {
                formattedString = adjustIndentation(formattedString, spaces: indentSpaces)
            }
            
            return .success(formattedString)
        } catch {
            return .failure(.parsingFailed(error.localizedDescription))
        }
    }
    
    /// Pretty-print JSON String with configurable indentation (default: 2 spaces).
    public func prettyPrint(string: String, indentSpaces: Int = 2) -> Result<String, JSONFormatterError> {
        guard let data = string.data(using: .utf8) else {
            return .failure(.invalidData)
        }
        return prettyPrint(data: data, indentSpaces: indentSpaces)
    }
    
    /// Minify JSON String into single-line format.
    public func minify(string: String) -> Result<String, JSONFormatterError> {
        guard let data = string.data(using: .utf8) else {
            return .failure(.invalidData)
        }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            let minifiedData = try JSONSerialization.data(
                withJSONObject: jsonObject,
                options: [.sortedKeys, .withoutEscapingSlashes]
            )
            guard let minifiedString = String(data: minifiedData, encoding: .utf8) else {
                return .failure(.invalidData)
            }
            return .success(minifiedString)
        } catch {
            return .failure(.parsingFailed(error.localizedDescription))
        }
    }
    
    public func isValidJSON(data: Data) -> Bool {
        guard !data.isEmpty else { return false }
        return (try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])) != nil
    }
    
    private func adjustIndentation(_ json: String, spaces: Int) -> String {
        let lines = json.components(separatedBy: "\n")
        let targetIndent = String(repeating: " ", count: spaces)
        
        var resultLines: [String] = []
        for line in lines {
            var spaceCount = 0
            for char in line {
                if char == " " {
                    spaceCount += 1
                } else {
                    break
                }
            }
            let level = spaceCount / 4
            let remainingSpaces = spaceCount % 4
            let newIndent = String(repeating: targetIndent, count: level) + String(repeating: " ", count: remainingSpaces)
            let trimmedContent = line.dropFirst(spaceCount)
            resultLines.append(newIndent + trimmedContent)
        }
        return resultLines.joined(separator: "\n")
    }
}
