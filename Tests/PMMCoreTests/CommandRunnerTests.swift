import Testing
@testable import PMMCore

@Test func systemCommandRunnerDrainsLargeOutputWhileProcessRuns() throws {
    let result = try SystemCommandRunner().run("/bin/sh", ["-c", "yes x | head -c 200000"])

    #expect(result.status == 0)
    #expect(result.stdout.count == 200_000)
}
