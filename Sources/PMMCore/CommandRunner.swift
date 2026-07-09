import Foundation
import Darwin

public struct CommandResult: Sendable {
    public let stdout: String
    public let stderr: String
    public let status: Int32
}

public struct CommandRunOptions: Sendable, Equatable {
    public var terminal: Bool
    public var environment: [String: String]

    public init(terminal: Bool = false, environment: [String: String] = [:]) {
        self.terminal = terminal
        self.environment = environment
    }
}

public protocol CommandRunning: Sendable {
    func run(_ executable: String, _ arguments: [String]) throws -> CommandResult
    func run(
        _ executable: String,
        _ arguments: [String],
        options: CommandRunOptions,
        onOutput: (@Sendable (String) -> Void)?
    ) throws -> CommandResult
}

public extension CommandRunning {
    func run(
        _ executable: String,
        _ arguments: [String],
        options: CommandRunOptions,
        onOutput: (@Sendable (String) -> Void)? = nil
    ) throws -> CommandResult {
        try run(executable, arguments)
    }

    func run(
        _ executable: String,
        _ arguments: [String],
        options: CommandRunOptions
    ) throws -> CommandResult {
        try run(executable, arguments, options: options, onOutput: nil)
    }
}

public struct SystemCommandRunner: CommandRunning {
    public init() {}

    public func run(_ executable: String, _ arguments: [String]) throws -> CommandResult {
        try run(executable, arguments, options: CommandRunOptions(), onOutput: nil)
    }

    public func run(
        _ executable: String,
        _ arguments: [String],
        options: CommandRunOptions,
        onOutput: (@Sendable (String) -> Void)? = nil
    ) throws -> CommandResult {
        if options.terminal {
            return try runInTerminal(executable, arguments, options: options, onOutput: onOutput)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        if !options.environment.isEmpty {
            process.environment = ProcessInfo.processInfo.environment.merging(options.environment) { _, new in new }
        }

        let output = Pipe()
        let error = Pipe()
        process.standardOutput = output
        process.standardError = error

        try process.run()
        let stdout = AsyncPipeReader(output, onOutput: onOutput)
        let stderr = AsyncPipeReader(error, onOutput: onOutput)
        stdout.start()
        stderr.start()
        process.waitUntilExit()

        return CommandResult(
            stdout: String(data: stdout.data(), encoding: .utf8) ?? "",
            stderr: String(data: stderr.data(), encoding: .utf8) ?? "",
            status: process.terminationStatus
        )
    }

    private func runInTerminal(
        _ executable: String,
        _ arguments: [String],
        options: CommandRunOptions,
        onOutput: (@Sendable (String) -> Void)?
    ) throws -> CommandResult {
        var master: Int32 = -1
        var slave: Int32 = -1
        guard openpty(&master, &slave, nil, nil, nil) == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }

        let masterHandle = FileHandle(fileDescriptor: master, closeOnDealloc: true)
        let slaveHandle = FileHandle(fileDescriptor: slave, closeOnDealloc: true)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.environment = ProcessInfo.processInfo.environment.merging(terminalEnvironment(options.environment)) { _, new in new }
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = slaveHandle
        process.standardError = slaveHandle

        try process.run()
        try? slaveHandle.close()

        let output = AsyncFileHandleReader(masterHandle, onOutput: onOutput)
        output.start()
        process.waitUntilExit()

        return CommandResult(
            stdout: String(data: output.data(), encoding: .utf8) ?? "",
            stderr: "",
            status: process.terminationStatus
        )
    }

    private func terminalEnvironment(_ overrides: [String: String]) -> [String: String] {
        [
            "TERM": "xterm-256color",
            "COLORTERM": "truecolor",
            "CLICOLOR_FORCE": "1",
            "FORCE_COLOR": "3",
            "HOMEBREW_COLOR": "1",
        ].merging(overrides) { _, new in new }
    }
}

private final class AsyncPipeReader: @unchecked Sendable {
    private let pipe: Pipe
    private let onOutput: (@Sendable (String) -> Void)?
    private let lock = NSLock()
    private var chunks = Data()
    private let done = DispatchSemaphore(value: 0)

    init(_ pipe: Pipe, onOutput: (@Sendable (String) -> Void)? = nil) {
        self.pipe = pipe
        self.onOutput = onOutput
    }

    func start() {
        DispatchQueue.global(qos: .utility).async {
            var data = Data()
            while true {
                let chunk = self.pipe.fileHandleForReading.availableData
                if chunk.isEmpty { break }
                data.append(chunk)
                let text = String(decoding: chunk, as: UTF8.self)
                if !text.isEmpty {
                    self.onOutput?(text)
                }
            }
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

private final class AsyncFileHandleReader: @unchecked Sendable {
    private let handle: FileHandle
    private let onOutput: (@Sendable (String) -> Void)?
    private let lock = NSLock()
    private var chunks = Data()
    private let done = DispatchSemaphore(value: 0)

    init(_ handle: FileHandle, onOutput: (@Sendable (String) -> Void)? = nil) {
        self.handle = handle
        self.onOutput = onOutput
    }

    func start() {
        DispatchQueue.global(qos: .utility).async {
            var data = Data()
            while true {
                let chunk = self.handle.availableData
                if chunk.isEmpty { break }
                data.append(chunk)
                let text = String(decoding: chunk, as: UTF8.self)
                if !text.isEmpty {
                    self.onOutput?(text)
                }
            }
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
