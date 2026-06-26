import Foundation
import Testing
@testable import PMMCore

private struct FakeRunner: CommandRunning {
    let responses: [String: CommandResult]

    func run(_ executable: String, _ arguments: [String]) throws -> CommandResult {
        responses[([executable] + arguments).joined(separator: " ")] ?? CommandResult(stdout: "", stderr: "", status: 0)
    }
}

@Test func npmScannerUsesGlobalRootPrefixOutdatedAndPackageBinNames() throws {
    let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    let root = temp.appendingPathComponent("lib/node_modules", isDirectory: true)
    let package = root.appendingPathComponent("@scope/tool", isDirectory: true)
    let bin = temp.appendingPathComponent("bin", isDirectory: true)
    try FileManager.default.createDirectory(at: package, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: bin, withIntermediateDirectories: true)
    try """
    {"name":"@scope/tool","version":"1.0.0","bin":{"tool":"cli.js"}}
    """.write(to: package.appendingPathComponent("package.json"), atomically: true, encoding: .utf8)
    FileManager.default.createFile(atPath: bin.appendingPathComponent("tool").path, contents: Data())
    defer { try? FileManager.default.removeItem(at: temp) }

    let runner = FakeRunner(responses: [
        "/fake/npm root -g": CommandResult(stdout: "\(root.path)\n", stderr: "", status: 0),
        "/fake/npm prefix -g": CommandResult(stdout: "\(temp.path)\n", stderr: "", status: 0),
        "/fake/npm ls -g --depth=0 --json": CommandResult(stdout: #"{"dependencies":{"@scope/tool":{"version":"1.0.0"}}}"#, stderr: "", status: 0),
        "/fake/npm outdated -g --json": CommandResult(stdout: #"{"@scope/tool":{"current":"1.0.0","latest":"1.2.0"}}"#, stderr: "", status: 1),
    ])
    let scanner = PackageScanner(runner: runner, toolPaths: ["npm": "/fake/npm"])

    let packages = try scanner.scanNPM(database: PackageDatabase(npms: [
        "@scope/tool": PackageMetadata(summary: "A scoped CLI", category: "developer-tools", homepage: nil, version: "1.2.0")
    ]))

    #expect(packages == [
        ManagedPackage(
            manager: .npm,
            name: "@scope/tool",
            installedVersion: "1.0.0",
            latestVersion: "1.2.0",
            summary: "A scoped CLI",
            category: "developer-tools",
            installLocation: package.path,
            binaryPath: bin.appendingPathComponent("tool").path
        )
    ])
}

@Test func homebrewScannerKeepsOnlyRequestedFormulaeAndCasks() throws {
    let runner = FakeRunner(responses: [
        "/fake/brew leaves --installed-on-request": CommandResult(stdout: "git\n", stderr: "", status: 0),
        "/fake/brew outdated --json=v2": CommandResult(stdout: #"{"formulae":[],"casks":[]}"#, stderr: "", status: 0),
        "/fake/brew list --versions --formula": CommandResult(stdout: "git 2.50.0\nopenssl@3 3.5.0\n", stderr: "", status: 0),
        "/fake/brew list --versions --cask": CommandResult(stdout: "visual-studio-code 1.101.2\n", stderr: "", status: 0),
    ])
    let scanner = PackageScanner(runner: runner, toolPaths: ["brew": "/fake/brew"])

    let packages = try scanner.scanHomebrew(database: PackageDatabase())

    #expect(packages.map(\.name) == ["git", "visual-studio-code"])
}

@Test func npxScannerDeduplicatesCacheCopiesByPackageAndVersion() throws {
    let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: home) }

    for cacheID in ["a", "b"] {
        let package = home.appendingPathComponent(".npm/_npx/\(cacheID)/node_modules/acorn", isDirectory: true)
        let transitive = home.appendingPathComponent(".npm/_npx/\(cacheID)/node_modules/commander", isDirectory: true)
        try FileManager.default.createDirectory(at: package, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: transitive, withIntermediateDirectories: true)
        try #"{"packages":{"":{"dependencies":{"acorn":"8.16.0"}}}}"#
            .write(to: home.appendingPathComponent(".npm/_npx/\(cacheID)/package-lock.json"), atomically: true, encoding: .utf8)
        try #"{"name":"acorn","version":"8.16.0"}"#
            .write(to: package.appendingPathComponent("package.json"), atomically: true, encoding: .utf8)
        try #"{"name":"commander","version":"14.0.0"}"#
            .write(to: transitive.appendingPathComponent("package.json"), atomically: true, encoding: .utf8)
    }

    let scanner = PackageScanner(runner: FakeRunner(responses: [:]), homeDirectory: home)
    let packages = try scanner.scanNPX(database: PackageDatabase(npms: [
        "acorn": PackageMetadata(summary: nil, category: nil, homepage: nil, version: "8.17.0")
    ]))

    #expect(packages.count == 1)
    #expect(packages.first?.isOutdated == true)
    #expect(packages.first?.name == "acorn")
}
