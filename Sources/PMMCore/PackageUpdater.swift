import Foundation

public struct PackageUpdater: Sendable {
    private let runner: CommandRunning
    private let toolPaths: [String: String]

    public init(
        runner: CommandRunning = SystemCommandRunner(),
        toolPaths: [String: String] = [:]
    ) {
        self.runner = runner
        self.toolPaths = toolPaths
    }

    public func update(_ package: ManagedPackage, onProgress: (@Sendable (PackageCommandProgress) -> Void)? = nil) throws {
        guard package.isOutdated else { return }
        switch package.manager {
        case .cargoInstall:
            try run("cargo", extraPaths: ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin"], ["install", package.packageToken, "--force", "--color", "always"], onProgress: onProgress)
        case .rustup:
            throw PackageUpdateError.unsupportedManager(package.manager)
        case .homebrew:
            try run("brew", extraPaths: ["/opt/homebrew/bin", "/usr/local/bin"], ["upgrade", package.packageToken], onProgress: onProgress)
        case .npm:
            try run("npm", extraPaths: ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin"], ["install", "-g", "\(package.packageToken)@latest"], onProgress: onProgress)
        case .npx:
            try run("npm", extraPaths: ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin"], ["exec", "--yes", "--package", "\(package.packageToken)@\(package.latestVersion ?? "latest")", "--", "true"], onProgress: onProgress)
        case .uv:
            if package.summary == "uv-managed Python", let latestVersion = package.latestVersion {
                try run("uv", extraPaths: ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin"], ["python", "install", latestVersion, "--color", "always"], onProgress: onProgress)
            } else {
                try run("uv", extraPaths: ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin"], ["tool", "upgrade", package.packageToken, "--color", "always"], onProgress: onProgress)
            }
        case .uvx:
            throw PackageUpdateError.unsupportedManager(package.manager)
        }
    }

    public static func supports(_ package: ManagedPackage) -> Bool {
        switch package.manager {
        case .cargoInstall, .homebrew, .npm, .npx, .uv: package.isOutdated
        case .rustup, .uvx: false
        }
    }

    private func run(
        _ executableName: String,
        extraPaths: [String],
        _ arguments: [String],
        onProgress: (@Sendable (PackageCommandProgress) -> Void)?
    ) throws {
        guard let executable = toolPaths[executableName] ?? firstExecutable(named: executableName, extraPaths: extraPaths) else {
            throw PackageUpdateError.missingExecutable(executableName)
        }
        let command = ([executableName] + arguments).joined(separator: " ")
        onProgress?(.started(command: command))
        let result = try runner.run(executable, arguments, options: CommandRunOptions(terminal: true)) { output in
            onProgress?(.output(output))
        }
        guard result.status == 0 else {
            throw PackageUpdateError.failed(command, result.stderr.isEmpty ? result.stdout : result.stderr)
        }
    }
}

public enum PackageCommandProgress: Sendable, Equatable {
    case started(command: String)
    case output(String)
}

public enum PackageUpdateError: LocalizedError, Equatable {
    case missingExecutable(String)
    case unsupportedManager(PackageManagerKind)
    case failed(String, String)

    public var errorDescription: String? {
        switch self {
        case .missingExecutable(let executable):
            "Could not find \(executable)."
        case .unsupportedManager(let manager):
            "Updating \(manager.title) packages is not supported."
        case .failed(let command, let stderr):
            stderr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "\(command) failed."
                : "\(command) failed: \(stderr.trimmingCharacters(in: .whitespacesAndNewlines))"
        }
    }
}
