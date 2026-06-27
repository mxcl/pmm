import AppKit
import Foundation
import PMMCore

enum MainWindowSection: String, CaseIterable, Identifiable, Sendable {
    case installed
    case outdated
    case newUpdated
    case homebrew
    case npm
    case npx
    case developerTools
    case cloudInfrastructure
    case networking
    case system
    case security
    case data
    case languageRuntime
    case media
    case productivity
    case science
    case games
    case toys
    case other
    case about

    var id: String { rawValue }

    static let librarySections: [MainWindowSection] = [.installed, .outdated]
    static let managerSections: [MainWindowSection] = [.homebrew, .npm, .npx]
    static let categorySections: [MainWindowSection] = [
        .developerTools, .cloudInfrastructure, .networking, .system, .security,
        .data, .languageRuntime, .media, .productivity, .science, .games, .toys, .other
    ].sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    static let categoryShortcutSections: [MainWindowSection] = [.newUpdated]
    static let utilitySections: [MainWindowSection] = []

    var title: String {
        switch self {
        case .installed: "Installed"
        case .outdated: "Outdated"
        case .newUpdated: "New / Updated"
        case .homebrew: "Homebrew"
        case .npm: "npm"
        case .npx: "npx"
        case .developerTools: "Developer Tools"
        case .cloudInfrastructure: "Cloud Infrastructure"
        case .networking: "Networking"
        case .system: "System"
        case .security: "Security"
        case .data: "Data"
        case .languageRuntime: "Language Runtime"
        case .media: "Media"
        case .productivity: "Productivity"
        case .science: "Science"
        case .games: "Games"
        case .toys: "Toys"
        case .other: "Other"
        case .about: "About"
        }
    }

    var systemImage: String {
        switch self {
        case .installed: "shippingbox"
        case .outdated: "clock"
        case .newUpdated: "sparkles"
        case .homebrew: "mug"
        case .npm: "shippingbox.circle"
        case .npx: "terminal"
        case .developerTools: "chevron.left.forwardslash.chevron.right"
        case .cloudInfrastructure: "cloud"
        case .networking: "network"
        case .system: "gearshape"
        case .security: "shield"
        case .data: "chart.bar.doc.horizontal"
        case .languageRuntime: "curlybraces"
        case .media: "play.rectangle"
        case .productivity: "checklist"
        case .science: "atom"
        case .games: "gamecontroller"
        case .toys: "puzzlepiece"
        case .other: "ellipsis"
        case .about: "info.circle"
        }
    }

    var categoryIdentifier: String? {
        switch self {
        case .developerTools: "developer-tools"
        case .cloudInfrastructure: "cloud-infrastructure"
        case .networking: "networking"
        case .system: "system"
        case .security: "security"
        case .data: "data"
        case .languageRuntime: "language-runtime"
        case .media: "media"
        case .productivity: "productivity"
        case .science: "science"
        case .games: "games"
        case .toys: "toys"
        case .other: "other"
        default: nil
        }
    }
}

enum MainWindowLinkTab: String, CaseIterable, Identifiable {
    case homepage
    var id: String { rawValue }
    var title: String { "Home" }
}

@MainActor
final class MainWindowModel: ObservableObject {
    @Published var selectedSection: MainWindowSection = .installed
    @Published private(set) var packages: [ManagedPackage] = []
    @Published private(set) var selectedPackage: ManagedPackage?
    @Published private(set) var isReloading = false
    @Published private(set) var errors: [String] = []
    @Published var searchText = ""

    nonisolated private static let newUpdatedLastClickedAtDefaultsKey = "MainWindowModel.newUpdatedLastClickedAt"

    private var inventory = PackageInventory(packages: [])
    private var packageIndex = PackageIndex.empty
    private var newUpdatedLastClickedAt: Date?
    private var newUpdatedSelectionDisplayCount: Int?
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        newUpdatedLastClickedAt = userDefaults.object(forKey: Self.newUpdatedLastClickedAtDefaultsKey) as? Date
    }

    var activeSidebarSection: MainWindowSection? { selectedSection }

    var visibleManagerSections: [MainWindowSection] {
        MainWindowSection.managerSections.filter { (count(for: $0) ?? 0) > 0 }
    }

    var visibleCategorySections: [MainWindowSection] {
        MainWindowSection.categorySections.filter { (count(for: $0) ?? 0) > 0 }
    }

    var displayedPackages: [ManagedPackage] {
        let base = packageIndex.packagesBySection[selectedSection] ?? []
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(query) || ($0.summary?.localizedCaseInsensitiveContains(query) == true) }
    }

    func reload() {
        isReloading = true
        Task {
            let (next, index) = await Task.detached { [newUpdatedLastClickedAt] in
                let db = await PackageDatabase.load()
                let next = await PackageScanner().inventory(database: db)
                return (next, PackageIndex(packages: next.packages, catalogPackages: db.catalogPackages, newUpdatedLastClickedAt: newUpdatedLastClickedAt))
            }.value
            inventory = next
            packageIndex = index
            packages = next.packages
            errors = next.errors
            selectedPackage = selectedPackage.flatMap { selected in displayedPackages.first { $0.id == selected.id } } ?? displayedPackages.first
            isReloading = false
        }
    }

    func selectSection(_ section: MainWindowSection) {
        if section == .newUpdated {
            newUpdatedSelectionDisplayCount = newUpdatedUnreadCount
            recordNewUpdatedSidebarClick()
        } else {
            newUpdatedSelectionDisplayCount = nil
        }
        selectedSection = section
        selectedPackage = displayedPackages.first
    }

    func select(_ package: ManagedPackage) {
        selectedPackage = package
    }

    func count(for section: MainWindowSection) -> Int? {
        switch section {
        case .about: nil
        case .newUpdated: newUpdatedSelectionDisplayCount ?? newUpdatedUnreadCount
        default: packageIndex.countsBySection[section]
        }
    }

    func open(url: URL?) {
        guard let url else { return }
        NSWorkspace.shared.open(url)
    }

    private var newUpdatedUnreadCount: Int? {
        packageIndex.newUpdatedUnreadCount
    }

    private func recordNewUpdatedSidebarClick() {
        let clickedAt = Date()
        newUpdatedLastClickedAt = clickedAt
        userDefaults.set(clickedAt, forKey: Self.newUpdatedLastClickedAtDefaultsKey)
    }
}

private struct PackageIndex: Sendable {
    static let empty = PackageIndex(packages: [], catalogPackages: [], newUpdatedLastClickedAt: nil)

    let packagesBySection: [MainWindowSection: [ManagedPackage]]
    let countsBySection: [MainWindowSection: Int]
    let newUpdatedUnreadCount: Int?

    init(packages: [ManagedPackage], catalogPackages: [ManagedPackage], newUpdatedLastClickedAt: Date?) {
        let newUpdated = catalogPackages
            .filter { $0.pulseKind != nil }
            .sorted { Self.updatedAt($0) > Self.updatedAt($1) }

        var bySection: [MainWindowSection: [ManagedPackage]] = [
            .installed: packages,
            .outdated: packages.filter(\.isOutdated),
            .newUpdated: newUpdated,
            .homebrew: packages.filter { $0.manager == .homebrew },
            .npm: packages.filter { $0.manager == .npm },
            .npx: packages.filter { $0.manager == .npx },
        ]

        for section in MainWindowSection.categorySections {
            bySection[section] = catalogPackages.filter { $0.category == section.categoryIdentifier }
        }

        packagesBySection = bySection
        countsBySection = bySection.mapValues(\.count)

        let unread = newUpdated.filter {
            guard let newUpdatedLastClickedAt else { return $0.pulseKind == "new" }
            return Self.updatedAt($0) > newUpdatedLastClickedAt
        }.count
        newUpdatedUnreadCount = unread > 0 ? unread : nil
    }

    private static func updatedAt(_ package: ManagedPackage) -> Date {
        guard let lastUpdatedAt = package.lastUpdatedAt else { return .distantPast }
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        let fractionalISO8601Formatter = ISO8601DateFormatter()
        fractionalISO8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return iso8601Formatter.date(from: lastUpdatedAt)
            ?? fractionalISO8601Formatter.date(from: lastUpdatedAt)
            ?? .distantPast
    }
}
