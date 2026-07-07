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

@Test func packageInstallerRunsManagerCommands() throws {
    let runner = RecordingRunner()
    let installer = PackageInstaller(runner: runner, toolPaths: ["brew": "/fake/brew", "npm": "/fake/npm"])

    try installer.install(package(.homebrew, "brew:git"))
    try installer.install(package(.homebrew, "brew:cask:visual-studio-code"))
    try installer.install(package(.npm, "npm:@scope/tool"))

    #expect(runner.commands == [
        "/fake/brew install git",
        "/fake/brew install --cask visual-studio-code",
        "/fake/npm install -g @scope/tool@latest",
    ])
}

@Test func packageInstallerThrowsOnFailedCommand() throws {
    let runner = RecordingRunner()
    runner.result = CommandResult(stdout: "", stderr: "refusing\n", status: 1)
    let installer = PackageInstaller(runner: runner, toolPaths: ["brew": "/fake/brew"])

    #expect(throws: PackageInstallError.failed("brew install git", "refusing\n")) {
        try installer.install(package(.homebrew, "brew:git"))
    }
}

@Test func packageInstallerRejectsUnsupportedManagers() throws {
    #expect(throws: PackageInstallError.unsupportedManager(.rustup)) {
        try PackageInstaller().install(package(.rustup, "rustup:rustup"))
    }
}

private func package(_ manager: PackageManagerKind, _ name: String) -> ManagedPackage {
    ManagedPackage(manager: manager, identifier: name, installedVersion: nil, latestVersion: "1.0.0")
}
