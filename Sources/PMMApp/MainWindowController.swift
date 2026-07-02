import AppKit
import SwiftUI

@MainActor
final class MainWindowController: NSSplitViewController {
    private let model = MainWindowModel()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor @preconcurrency required dynamic init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        splitView.isVertical = true
        splitView.dividerStyle = .thin

        addSplitViewItem(sidebarItem())
        addSplitViewItem(contentItem(MainWindowPackageListView(model: model), width: 252, minimumWidth: 252))
        addSplitViewItem(contentItem(MainWindowDossierView(model: model), width: 252, minimumWidth: 252))
        addSplitViewItem(contentItem(MainWindowLinksView(model: model), width: 624, minimumWidth: 350))
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        model.reload()
    }

    func makeToolbar() -> NSToolbar {
        let toolbar = NSToolbar(identifier: "PMMToolbar")
        toolbar.displayMode = .iconOnly
        toolbar.delegate = self
        return toolbar
    }

    @objc private func refresh(_ sender: Any?) {
        model.reload()
    }

    private func sidebarItem() -> NSSplitViewItem {
        let controller = NSHostingController(rootView: MainWindowSidebarView(model: model))
        let item = NSSplitViewItem(sidebarWithViewController: controller)
        item.minimumThickness = 250
        item.maximumThickness = 320
        item.preferredThicknessFraction = 0.20
        return item
    }

    private func contentItem<Content: View>(_ rootView: Content, width: CGFloat, minimumWidth: CGFloat) -> NSSplitViewItem {
        let controller = NSHostingController(rootView: rootView)
        let item = NSSplitViewItem(viewController: controller)
        item.minimumThickness = minimumWidth
        item.preferredThicknessFraction = 0
        controller.view.widthAnchor.constraint(greaterThanOrEqualToConstant: minimumWidth).isActive = true
        let widthConstraint = controller.view.widthAnchor.constraint(equalToConstant: width)
        widthConstraint.priority = .defaultLow
        widthConstraint.isActive = true
        return item
    }
}

extension MainWindowController: NSToolbarDelegate {
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.refresh, .flexibleSpace]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.flexibleSpace, .refresh]
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard itemIdentifier == .refresh else { return nil }
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: "Refresh")
        item.label = "Refresh"
        item.target = self
        item.action = #selector(refresh(_:))
        return item
    }
}

private extension NSToolbarItem.Identifier {
    static let refresh = NSToolbarItem.Identifier("PMMRefreshToolbarItem")
}
