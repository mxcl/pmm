import PMMCore

@MainActor
struct PreparedAppUpdateInstallation {
    let install: () async throws -> Void
    let discard: () async -> Void
}

@MainActor
struct AppUpdateInstallation {
    let prepare: () async throws -> PreparedAppUpdateInstallation
}

@MainActor
final class AppUpdateController {
    typealias Check = () async throws -> AppUpdateInstallation?

    private let checkForUpdate: Check
    private let publish: (AppUpdateHostState) -> Void
    private let requestHelperQuit: () -> Void
    private let waitForHelperExit: () async -> Bool
    private let quiesce: () -> Void
    private var installation: AppUpdateInstallation?

    private(set) var state: AppUpdateHostState

    init(
        initialState: AppUpdateHostState = AppUpdateHostState(),
        checkForUpdate: @escaping Check,
        publish: @escaping (AppUpdateHostState) -> Void,
        requestHelperQuit: @escaping () -> Void,
        waitForHelperExit: @escaping () async -> Bool,
        quiesce: @escaping () -> Void
    ) {
        state = initialState
        self.checkForUpdate = checkForUpdate
        self.publish = publish
        self.requestHelperQuit = requestHelperQuit
        self.waitForHelperExit = waitForHelperExit
        self.quiesce = quiesce
    }

    func check() async {
        guard !state.isChecking else { return }
        setState(AppUpdateHostState(isChecking: true, isAvailable: installation != nil))
        do {
            installation = try await checkForUpdate()
            setState(AppUpdateHostState(isAvailable: installation != nil))
        } catch {
            setState(AppUpdateHostState(isAvailable: installation != nil, errorMessage: error.localizedDescription))
        }
    }

    func install() async {
        if installation == nil { await check() }
        guard let installation else { return }

        let prepared: PreparedAppUpdateInstallation
        do {
            prepared = try await installation.prepare()
        } catch {
            self.installation = nil
            setState(AppUpdateHostState(errorMessage: error.localizedDescription))
            return
        }

        requestHelperQuit()
        guard await waitForHelperExit() else {
            await prepared.discard()
            self.installation = nil
            setState(AppUpdateHostState(errorMessage: "The menu bar helper did not quit in time."))
            return
        }

        quiesce()
        self.installation = nil
        do {
            try await prepared.install()
        } catch {
            setState(AppUpdateHostState(errorMessage: error.localizedDescription))
        }
    }

    private func setState(_ state: AppUpdateHostState) {
        self.state = state
        publish(state)
    }
}
