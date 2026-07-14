import Foundation
import Testing
@testable import PMMCore

@Test func commandPathPreservesPathOrderAndAppendsFallbacks() {
    #expect(commandPath("/custom/bin:/usr/bin") == "/custom/bin:/usr/bin:/usr/local/bin:/opt/homebrew/bin")
}

@Test func commandPathUsesFallbacksWhenPathIsMissing() {
    #expect(commandPath(nil) == "/usr/local/bin:/opt/homebrew/bin")
}

@Test func systemCommandRunnerAppendsFallbacksToChildPath() throws {
    let result = try SystemCommandRunner().run(
        "/bin/sh",
        ["-c", "printf %s \"$PATH\""],
        options: CommandRunOptions(environment: ["PATH": "/custom/bin"])
    )

    #expect(result.stdout == "/custom/bin:/usr/local/bin:/opt/homebrew/bin")
}

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

@Test func systemCommandRunnerTerminalModeReportsEightyColumns() throws {
    let result = try SystemCommandRunner().run(
        "/usr/bin/python3",
        ["-c", "import fcntl, struct, sys, termios; print(*struct.unpack('hhhh', fcntl.ioctl(1, termios.TIOCGWINSZ, b'\\0' * 8))[:2]); print(__import__('os').environ['COLUMNS'], __import__('os').environ['LINES'])"],
        options: CommandRunOptions(terminal: true)
    )

    let lines = result.stdout.split(whereSeparator: \.isNewline).map(String.init)
    #expect(lines == ["24 80", "80 24"])
}

@Test func streamingUTF8DecoderPreservesScalarsSplitAcrossChunks() {
    var decoder = IncrementalUTF8Decoder()

    #expect(decoder.decode(Data([0xE2])) == "")
    #expect(decoder.decode(Data([0x9C])) == "")
    #expect(decoder.decode(Data([0x94, 0x20, 0xF0, 0x9F])) == "✔ ")
    #expect(decoder.decode(Data([0x9A, 0x80])) == "🚀")
    #expect(decoder.finish() == "")
}
