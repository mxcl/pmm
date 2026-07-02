import Foundation

public struct HomebrewMaintenance: Sendable {
    private let runner: CommandRunning
    private let toolPaths: [String: String]

    public init(
        runner: CommandRunning = SystemCommandRunner(),
        toolPaths: [String: String] = [:]
    ) {
        self.runner = runner
        self.toolPaths = toolPaths
    }

    public func update() throws {
        guard let brew = toolPaths["brew"] ?? firstExecutable(named: "brew", extraPaths: ["/opt/homebrew/bin", "/usr/local/bin"]),
              !brew.isEmpty else {
            throw HomebrewMaintenanceError.missingExecutable("brew")
        }
        let result = try runner.run(brew, ["update"])
        guard result.status == 0 else {
            throw HomebrewMaintenanceError.failed("brew update", result.stderr)
        }
    }
}

public enum HomebrewMaintenanceError: LocalizedError, Equatable {
    case missingExecutable(String)
    case failed(String, String)

    public var errorDescription: String? {
        switch self {
        case .missingExecutable(let executable):
            "Could not find \(executable)."
        case .failed(let command, let stderr):
            stderr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "\(command) failed."
                : "\(command) failed: \(stderr.trimmingCharacters(in: .whitespacesAndNewlines))"
        }
    }
}
