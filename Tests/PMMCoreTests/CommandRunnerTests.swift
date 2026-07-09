import Foundation
import Testing
@testable import PMMCore

private final class StringRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var text = ""

    func append(_ value: String) {
        lock.lock()
        text += value
        lock.unlock()
    }

    var value: String {
        lock.lock()
        defer { lock.unlock() }
        return text
    }
}

@Test func systemCommandRunnerDrainsLargeOutputWhileProcessRuns() throws {
    let result = try SystemCommandRunner().run("/bin/sh", ["-c", "yes x | head -c 200000"])

    #expect(result.status == 0)
    #expect(result.stdout.count == 200_000)
}

@Test func systemCommandRunnerTerminalModeStreamsTTYOutput() throws {
    let streamed = StringRecorder()

    let result = try SystemCommandRunner().run(
        "/bin/sh",
        ["-c", "test -t 1 && printf tty || printf pipe"],
        options: CommandRunOptions(terminal: true)
    ) { output in
        streamed.append(output)
    }

    #expect(result.status == 0)
    #expect(result.stdout == "tty")
    #expect(streamed.value == "tty")
}
