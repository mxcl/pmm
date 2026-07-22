import Testing
@testable import PMMApp

@Test func dockBadgeShowsOutdatedPackageCount() {
    #expect(dockBadgeLabel(outdatedPackageCount: 3) == "3")
}

@Test func dockBadgeIsHiddenWithoutOutdatedPackages() {
    #expect(dockBadgeLabel(outdatedPackageCount: 0) == nil)
}
