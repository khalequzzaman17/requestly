import Foundation

public enum TestHarness {
    public static var totalTests = 0
    public static var passedTests = 0
    public static var failedTests = 0
    
    public static func runTest(_ name: String, block: () async throws -> Void) async {
        totalTests += 1
        print("  ▶ Running: \(name)...", terminator: "")
        fflush(stdout)
        
        let start = CFAbsoluteTimeGetCurrent()
        do {
            try await block()
            let duration = (CFAbsoluteTimeGetCurrent() - start) * 1000.0
            passedTests += 1
            print("\r  ✅ \u{001B}[32mPASSED\u{001B}[0m: \(name) (\(String(format: "%.1f", duration)) ms)")
        } catch {
            failedTests += 1
            print("\r  ❌ \u{001B}[31mFAILED\u{001B}[0m: \(name) - \(error.localizedDescription)")
        }
    }
    
    public static func assertEqual<T: Equatable>(_ a: T, _ b: T, _ message: String = "", file: StaticString = #file, line: UInt = #line) throws {
        if a != b {
            throw TestError.assertionFailed("Expected \(b) but got \(a). \(message) [\(file):\(line)]")
        }
    }
    
    public static func assertTrue(_ condition: Bool, _ message: String = "", file: StaticString = #file, line: UInt = #line) throws {
        if !condition {
            throw TestError.assertionFailed("Expected true but got false. \(message) [\(file):\(line)]")
        }
    }
    
    public static func assertFalse(_ condition: Bool, _ message: String = "", file: StaticString = #file, line: UInt = #line) throws {
        if condition {
            throw TestError.assertionFailed("Expected false but got true. \(message) [\(file):\(line)]")
        }
    }
    
    public static func assertNotNil(_ value: Any?, _ message: String = "", file: StaticString = #file, line: UInt = #line) throws {
        if value == nil {
            throw TestError.assertionFailed("Expected non-nil value but got nil. \(message) [\(file):\(line)]")
        }
    }
    
    public static func assertNil(_ value: Any?, _ message: String = "", file: StaticString = #file, line: UInt = #line) throws {
        if value != nil {
            throw TestError.assertionFailed("Expected nil but got \(String(describing: value)). \(message) [\(file):\(line)]")
        }
    }
}

public enum TestError: LocalizedError {
    case assertionFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .assertionFailed(let msg): return msg
        }
    }
}

