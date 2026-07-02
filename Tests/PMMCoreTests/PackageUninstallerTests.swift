import Foundation
import Testing
@testable import PMMCore

private final class RecordingRunner: CommandRunning, @unchecked Sendable {
    var commands: [String] = []
    var result = CommandResult(stdout: "", stderr: "", status: 0)

    func run(_ executable: String, _ arguments: [String]) throws -> CommandResult {
        commands.append(([executable] + arguments).joined(separator: " "))
        return result
    }
}

@Test func packageUninstallerRunsManagerCommands() throws {
    let runner = RecordingRunner()
    let uninstaller = PackageUninstaller(
        runner: runner,
        toolPaths: ["cargo": "/fake/cargo", "brew": "/fake/brew", "npm": "/fake/npm", "uv": "/fake/uv"]
    )

    try uninstaller.uninstall(package(.cargoInstall, "cargo:ripgrep", displayName: "Ripgrep"))
    try uninstaller.uninstall(package(.homebrew, "brew:git", displayName: "Git"))
    try uninstaller.uninstall(package(.npm, "npm:@scope/tool", displayName: "Scoped Tool"))
    try uninstaller.uninstall(package(.uv, "uv:tool:ruff", displayName: "Ruff", summary: "uv-installed tool", category: "language-runtime"))
    try uninstaller.uninstall(package(.uv, "uv:cpython:3.13", displayName: "uv Managed Python 3.13", installedVersion: "3.13.12", summary: "uv-managed Python", category: "language-runtime"))

    #expect(runner.commands == [
        "/fake/cargo uninstall ripgrep --color never",
        "/fake/brew uninstall git",
        "/fake/npm uninstall -g @scope/tool",
        "/fake/uv tool uninstall ruff --color never",
        "/fake/uv python uninstall 3.13.12 --color never",
    ])
}

@Test func packageUninstallerRemovesNpxCacheEntry() throws {
    let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    let packageURL = home.appendingPathComponent(".npm/_npx/cache-id/node_modules/acorn", isDirectory: true)
    try FileManager.default.createDirectory(at: packageURL, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: home) }

    try PackageUninstaller(homeDirectory: home).uninstall(package(.npx, "acorn", installLocation: packageURL.path))

    #expect(!FileManager.default.fileExists(atPath: home.appendingPathComponent(".npm/_npx/cache-id").path))
}

@Test func packageUninstallerThrowsOnFailedCommand() throws {
    let runner = RecordingRunner()
    runner.result = CommandResult(stdout: "", stderr: "refusing\n", status: 1)
    let uninstaller = PackageUninstaller(runner: runner, toolPaths: ["brew": "/fake/brew"])

    #expect(throws: PackageUninstallError.failed("brew uninstall git", "refusing\n")) {
        try uninstaller.uninstall(package(.homebrew, "git"))
    }
}

private func package(
    _ manager: PackageManagerKind,
    _ name: String,
    displayName: String? = nil,
    installedVersion: String = "1.0.0",
    summary: String? = nil,
    category: String? = nil,
    installLocation: String? = nil
) -> ManagedPackage {
    ManagedPackage(
        manager: manager,
        identifier: name,
        displayName: displayName,
        installedVersion: installedVersion,
        latestVersion: "1.0.0",
        summary: summary,
        category: category,
        installLocation: installLocation
    )
}
