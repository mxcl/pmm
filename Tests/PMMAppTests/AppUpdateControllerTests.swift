import Foundation
import PMMCore
import Testing
@testable import PMMApp

@Test @MainActor func appUpdateCheckPublishesAvailableStateWithoutPreparing() async {
    var prepared = false
    let controller = AppUpdateController(
        checkForUpdate: {
            AppUpdateInstallation {
                prepared = true
                return PreparedAppUpdateInstallation(install: {}, discard: {})
            }
        },
        publish: { _ in },
        requestHelperQuit: {},
        waitForHelperExit: { true },
        quiesce: {}
    )

    await controller.check()

    #expect(controller.state == AppUpdateHostState(isAvailable: true))
    #expect(!prepared)
}

@Test @MainActor func appUpdateCheckPublishesCurrentState() async {
    let controller = testController(checkForUpdate: { nil })

    await controller.check()

    #expect(controller.state == AppUpdateHostState())
}

@Test @MainActor func appUpdateCheckPublishesError() async {
    let controller = testController(checkForUpdate: { throw AppUpdateTestError.failed })

    await controller.check()

    #expect(controller.state.errorMessage == "failed")
    #expect(!controller.state.isAvailable)
}

@Test @MainActor func installPreparesBeforeQuiescingAndInstalling() async {
    var events: [String] = []
    let controller = AppUpdateController(
        initialState: AppUpdateHostState(isAvailable: true),
        checkForUpdate: {
            events.append("check")
            return AppUpdateInstallation {
                events.append("prepare")
                return PreparedAppUpdateInstallation(
                    install: { events.append("install") },
                    discard: { events.append("discard") }
                )
            }
        },
        publish: { _ in },
        requestHelperQuit: { events.append("quit helper") },
        waitForHelperExit: {
            events.append("helper exited")
            return true
        },
        quiesce: { events.append("quiesce") }
    )

    await controller.install()

    #expect(events == ["check", "prepare", "quit helper", "helper exited", "quiesce", "install"])
}

@Test @MainActor func failedHelperExitDiscardsPreparedUpdate() async {
    var discarded = false
    var quiesced = false
    let controller = AppUpdateController(
        checkForUpdate: {
            AppUpdateInstallation {
                PreparedAppUpdateInstallation(
                    install: {},
                    discard: { discarded = true }
                )
            }
        },
        publish: { _ in },
        requestHelperQuit: {},
        waitForHelperExit: { false },
        quiesce: { quiesced = true }
    )

    await controller.install()

    #expect(discarded)
    #expect(!quiesced)
    #expect(controller.state.errorMessage == "The menu bar helper did not quit in time.")
}

@MainActor
private func testController(
    checkForUpdate: @escaping AppUpdateController.Check
) -> AppUpdateController {
    AppUpdateController(
        checkForUpdate: checkForUpdate,
        publish: { _ in },
        requestHelperQuit: {},
        waitForHelperExit: { true },
        quiesce: {}
    )
}

private enum AppUpdateTestError: LocalizedError {
    case failed

    var errorDescription: String? { "failed" }
}
