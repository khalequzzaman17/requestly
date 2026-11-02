import Foundation

@main
struct TestRunner {
    static func main() async {
        print("\u{001B}[1;36m===================================================\u{001B}[0m")
        print("\u{001B}[1;36m       REQUESTLY NATIVE TEST SUITE EXECUTION       \u{001B}[0m")
        print("\u{001B}[1;36m===================================================\u{001B}[0m")
        
        let start = CFAbsoluteTimeGetCurrent()
        
        await JSONFormattingTests.runAll()
        await DatabaseTests.runAll()
        await ImportExportTests.runAll()
        await SecurityAndVariableTests.runAll()
        await NetworkingTests.runAll()
        
        let totalDuration = (CFAbsoluteTimeGetCurrent() - start) * 1000.0
        
        print("\n\u{001B}[1;36m===================================================\u{001B}[0m")
        print("Total Tests: \(TestHarness.totalTests)")
        print("\u{001B}[32mPassed: \(TestHarness.passedTests)\u{001B}[0m")
        if TestHarness.failedTests > 0 {
            print("\u{001B}[31mFailed: \(TestHarness.failedTests)\u{001B}[0m")
            print("Total Duration: \(String(format: "%.1f", totalDuration)) ms")
            exit(1)
        } else {
            print("Failed: 0")
            print("Total Duration: \(String(format: "%.1f", totalDuration)) ms")
            print("\u{001B}[1;32mALL TESTS PASSED SUCCESSFULLY! 🎉\u{001B}[0m")
            exit(0)
        }
    }
}

