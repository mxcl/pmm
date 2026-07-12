import Foundation
import Testing
@testable import PMMCore

@Test func remoteControlParsesEveryCommand() throws {
    #expect(try RemoteControlCommand.parse(["inventory", "--protocol", "1"]) == .inventory)
    #expect(try RemoteControlCommand.parse(["update-all", "--protocol", "1"]) == .updateAll)
    #expect(try RemoteControlCommand.parse([
        "update", "--protocol", "1", "--manager", "npm", "--id", "npm:eslint:/opt/npm/eslint",
    ]) == .update(manager: .npm, packageID: "npm:eslint:/opt/npm/eslint"))
    #expect(try RemoteControlCommand.parse([
        "uninstall", "--manager", "homebrew", "--id", "brew:wget:/opt/homebrew/Cellar/wget", "--protocol", "1",
    ]) == .uninstall(manager: .homebrew, packageID: "brew:wget:/opt/homebrew/Cellar/wget"))
}

@Test func remoteControlRejectsMissingOrIncompatibleProtocol() {
    #expect(throws: RemoteControlCommandError.incompatibleProtocol) {
        try RemoteControlCommand.parse(["inventory"])
    }
    #expect(throws: RemoteControlCommandError.incompatibleProtocol) {
        try RemoteControlCommand.parse(["inventory", "--protocol", "2"])
    }
}

@Test func remoteControlResponseRoundTrips() throws {
    let response = RemoteControlResponse(
        inventory: PackageInventory(packages: []),
        failures: [RemoteControlFailure(packageID: "npm:missing", message: "failed")]
    )
    let decoded = try JSONDecoder().decode(RemoteControlResponse.self, from: JSONEncoder().encode(response))
    #expect(decoded == response)
}
