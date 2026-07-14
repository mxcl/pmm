import Foundation
import Testing
@testable import PMMMenuBar

@Test func menuBarHelperTargetsOuterAppBundle() {
    let helper = URL(fileURLWithPath: "/Applications/Package Manager Manager.app/Contents/Library/LoginItems/Package Manager Manager Menu.app")

    let mainApp = MenuBarAppDelegate.mainAppURL(containing: helper)

    #expect(mainApp.path == "/Applications/Package Manager Manager.app")
}
