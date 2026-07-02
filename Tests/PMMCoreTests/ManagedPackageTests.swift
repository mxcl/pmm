import Testing
@testable import PMMCore

@Test func packageWithLatestAmongInstalledVersionsIsNotOutdated() {
    let package = ManagedPackage(
        manager: .npx,
        name: "playwright",
        installedVersion: "1.2.0",
        installedVersions: ["1.0.0", "1.2.0"],
        latestVersion: "1.2.0"
    )

    #expect(package.isOutdated == false)
    #expect(package.otherInstalledVersions == ["1.0.0"])
}

@Test func packageWithoutLatestAmongInstalledVersionsIsOutdated() {
    let package = ManagedPackage(
        manager: .npx,
        name: "playwright",
        installedVersion: "1.2.0",
        installedVersions: ["1.0.0", "1.2.0"],
        latestVersion: "1.3.0"
    )

    #expect(package.isOutdated == true)
}

@Test func singleVersionPackageOutdatedBehaviorIsUnchanged() {
    #expect(ManagedPackage(manager: .npm, name: "old", installedVersion: "1.0.0", latestVersion: "1.1.0").isOutdated)
    #expect(!ManagedPackage(manager: .npm, name: "current", installedVersion: "1.1.0", latestVersion: "1.1.0").isOutdated)
}
