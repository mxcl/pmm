import Foundation

public struct PackageInstaller: Sendable {
    private let runner: CommandRunning
    private let toolPaths: [String: String]

    public init(
        runner: CommandRunning = SystemCommandRunner(),
        toolPaths: [String: String] = [:]
    ) {
        self.runner = runner
        self.toolPaths = toolPaths
    }

    public func install(_ package: ManagedPackage) throws {
        guard package.installedVersion == nil else { return }
        switch package.manager {
        case .homebrew:
            let arguments = package.identifier.hasPrefix("brew:cask:")
                ? ["install", "--cask", package.packageToken]
                : ["install", package.packageToken]
            try run("brew", extraPaths: ["/opt/homebrew/bin", "/usr/local/bin"], arguments)
        case .npm:
            try run("npm", extraPaths: ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin"], ["install", "-g", "\(package.packageToken)@latest"])
        case .cargoInstall, .rustup, .npx, .uv, .uvx:
            throw PackageInstallError.unsupportedManager(package.manager)
        }
    }

    public static func supports(_ package: ManagedPackage) -> Bool {
        package.installedVersion == nil && [.homebrew, .npm].contains(package.manager)
    }

    private func run(_ executableName: String, extraPaths: [String], _ arguments: [String]) throws {
        guard let executable = toolPaths[executableName] ?? firstExecutable(named: executableName, extraPaths: extraPaths) else {
            throw PackageInstallError.missingExecutable(executableName)
        }
        let result = try runner.run(executable, arguments)
        guard result.status == 0 else {
            throw PackageInstallError.failed(([executableName] + arguments).joined(separator: " "), result.stderr)
        }
    }
}

public enum PackageInstallError: LocalizedError, Equatable {
    case missingExecutable(String)
    case unsupportedManager(PackageManagerKind)
    case failed(String, String)

    public var errorDescription: String? {
        switch self {
        case .missingExecutable(let executable):
            "Could not find \(executable)."
        case .unsupportedManager(let manager):
            "Installing \(manager.title) packages is not supported."
        case .failed(let command, let stderr):
            stderr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "\(command) failed."
                : "\(command) failed: \(stderr.trimmingCharacters(in: .whitespacesAndNewlines))"
        }
    }
}
