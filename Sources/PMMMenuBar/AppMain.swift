import AppKit

@main
enum PMMMenuBarMain {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = MenuBarAppDelegate()
        app.setActivationPolicy(.accessory)
        app.delegate = delegate
        app.run()
    }
}
