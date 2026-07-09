import Foundation
import Testing
@testable import PMMCore

private final class RecordingRunner: CommandRunning, @unchecked Sendable {
    var commands: [String] = []
    var options: [CommandRunOptions] = []
    var streamedOutput = ""
    var result = CommandResult(stdout: "", stderr: "", status: 0)

    func run(_ executable: String, _ arguments: [String]) throws -> CommandResult {
        try run(executable, arguments, options: CommandRunOptions(), onOutput: nil)
    }

    func run(
        _ executable: String,
        _ arguments: [String],
        options: CommandRunOptions,
        onOutput: (@Sendable (String) -> Void)? = nil
    ) throws -> CommandResult {
        commands.append(([executable] + arguments).joined(separator: " "))
        self.options.append(options)
        if !streamedOutput.isEmpty {
            onOutput?(streamedOutput)
        }
        return result
    }
}

private final class ProgressRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var events: [PackageCommandProgress] = []

    func append(_ event: PackageCommandProgress) {
        lock.lock()
        events.append(event)
        lock.unlock()
    }

    var values: [PackageCommandProgress] {
        lock.lock()
        defer { lock.unlock() }
        return events
    }
}

@Test func packageUpdaterRunsManagerCommands() throws {
    let runner = RecordingRunner()
    let updater = PackageUpdater(
        runner: runner,
        toolPaths: ["cargo": "/fake/cargo", "brew": "/fake/brew", "npm": "/fake/npm", "uv": "/fake/uv"]
    )

    try updater.update(package(.cargoInstall, "cargo:ripgrep", displayName: "Ripgrep"))
    try updater.update(package(.homebrew, "brew:git", displayName: "Git"))
    try updater.update(package(.npm, "npm:@scope/tool", displayName: "Scoped Tool"))
    try updater.update(package(.npx, "npx:acorn", displayName: "Acorn"))
    try updater.update(package(.uv, "uv:tool:ruff", displayName: "Ruff", summary: "uv-installed tool", category: "language-runtime"))
    try updater.update(package(.uv, "uv:cpython:3.13", displayName: "uv Managed Python 3.13", latestVersion: "3.13.14", summary: "uv-managed Python", category: "language-runtime"))

    #expect(runner.commands == [
        "/fake/cargo install ripgrep --force --color always",
        "/fake/brew upgrade git",
        "/fake/npm install -g @scope/tool@latest",
        "/fake/npm exec --yes --package acorn@2.0.0 -- true",
        "/fake/uv tool upgrade ruff --color always",
        "/fake/uv python install 3.13.14 --color always",
    ])
    #expect(runner.options.map(\.terminal) == Array(repeating: true, count: 6))
}

@Test func packageUpdaterReportsCommandAndOutputProgress() throws {
    let runner = RecordingRunner()
    runner.streamedOutput = "\u{1B}[32mupdated\u{1B}[0m\n"
    let updater = PackageUpdater(runner: runner, toolPaths: ["brew": "/fake/brew"])
    let progress = ProgressRecorder()

    try updater.update(package(.homebrew, "brew:git")) { event in
        progress.append(event)
    }

    #expect(progress.values == [
        .started(command: "brew upgrade git"),
        .output("\u{1B}[32mupdated\u{1B}[0m\n"),
    ])
}

@Test func packageUpdaterThrowsOnFailedCommand() throws {
    let runner = RecordingRunner()
    runner.result = CommandResult(stdout: "", stderr: "refusing\n", status: 1)
    let updater = PackageUpdater(runner: runner, toolPaths: ["brew": "/fake/brew"])

    #expect(throws: PackageUpdateError.failed("brew upgrade git", "refusing\n")) {
        try updater.update(package(.homebrew, "git"))
    }
}

@Test func packageUpdaterThrowsOnUnsupportedManagers() throws {
    let updater = PackageUpdater()

    #expect(throws: PackageUpdateError.unsupportedManager(.rustup)) {
        try updater.update(package(.rustup, "rustup:rustup"))
    }
    #expect(throws: PackageUpdateError.unsupportedManager(.uvx)) {
        try updater.update(package(.uvx, "ruff"))
    }
}

private func package(
    _ manager: PackageManagerKind,
    _ name: String,
    displayName: String? = nil,
    latestVersion: String = "2.0.0",
    summary: String? = nil,
    category: String? = nil
) -> ManagedPackage {
    ManagedPackage(
        manager: manager,
        identifier: name,
        displayName: displayName,
        installedVersion: "1.0.0",
        latestVersion: latestVersion,
        summary: summary,
        category: category
    )
}
