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

@Test func homebrewMaintenanceRunsBrewUpdate() throws {
    let runner = RecordingRunner()
    let maintenance = HomebrewMaintenance(runner: runner, toolPaths: ["brew": "/fake/brew"])

    try maintenance.update()

    #expect(runner.commands == ["/fake/brew update"])
}

@Test func homebrewMaintenanceThrowsWhenBrewIsMissing() {
    let maintenance = HomebrewMaintenance(runner: RecordingRunner(), toolPaths: ["brew": ""])

    #expect(throws: HomebrewMaintenanceError.missingExecutable("brew")) {
        try maintenance.update()
    }
}

@Test func homebrewMaintenanceThrowsOnFailedUpdate() {
    let runner = RecordingRunner()
    runner.result = CommandResult(stdout: "", stderr: "no network\n", status: 1)
    let maintenance = HomebrewMaintenance(runner: runner, toolPaths: ["brew": "/fake/brew"])

    #expect(throws: HomebrewMaintenanceError.failed("brew update", "no network\n")) {
        try maintenance.update()
    }
}
