import Foundation

public struct CommandResult: Sendable {
    public let stdout: String
    public let stderr: String
    public let status: Int32
}

public protocol CommandRunning: Sendable {
    func run(_ executable: String, _ arguments: [String]) throws -> CommandResult
}

public struct SystemCommandRunner: CommandRunning {
    public init() {}

    public func run(_ executable: String, _ arguments: [String]) throws -> CommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        let output = Pipe()
        let error = Pipe()
        process.standardOutput = output
        process.standardError = error

        try process.run()
        let stdout = AsyncPipeReader(output)
        let stderr = AsyncPipeReader(error)
        stdout.start()
        stderr.start()
        process.waitUntilExit()

        return CommandResult(
            stdout: String(data: stdout.data(), encoding: .utf8) ?? "",
            stderr: String(data: stderr.data(), encoding: .utf8) ?? "",
            status: process.terminationStatus
        )
    }
}

private final class AsyncPipeReader: @unchecked Sendable {
    private let pipe: Pipe
    private let lock = NSLock()
    private var chunks = Data()
    private let done = DispatchSemaphore(value: 0)

    init(_ pipe: Pipe) {
        self.pipe = pipe
    }

    func start() {
        DispatchQueue.global(qos: .utility).async {
            let data = self.pipe.fileHandleForReading.readDataToEndOfFile()
            self.lock.lock()
            self.chunks = data
            self.lock.unlock()
            self.done.signal()
        }
    }

    func data() -> Data {
        done.wait()
        lock.lock()
        defer { lock.unlock() }
        return chunks
    }
}

public func firstExecutable(named name: String, extraPaths: [String] = []) -> String? {
    let pathParts = (ProcessInfo.processInfo.environment["PATH"] ?? "")
        .split(separator: ":")
        .map(String.init)
    let candidates = (extraPaths + pathParts).map { "\($0)/\(name)" }
    return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
}
