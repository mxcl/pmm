import Foundation

public enum PackageManagerKind: String, Codable, CaseIterable, Sendable {
    case cargoInstall = "cargo-install"
    case homebrew
    case npm
    case npx
    case uv
    case uvx

    public var title: String {
        switch self {
        case .cargoInstall: "cargo install"
        case .homebrew: "Homebrew"
        case .npm: "npm"
        case .npx: "npx"
        case .uv: "uv"
        case .uvx: "uvx"
        }
    }
}

public struct ManagedPackage: Codable, Equatable, Identifiable, Sendable {
    public var id: String { "\(manager.rawValue):\(name):\(installLocation ?? "")" }

    public let manager: PackageManagerKind
    public let name: String
    public let installedVersion: String?
    public let installedVersions: [String]
    public let latestVersion: String?
    public let summary: String?
    public let category: String?
    public let homepage: String?
    public let docs: String?
    public let repo: String?
    public let lastUpdatedAt: String?
    public let pulseKind: String?
    public let installLocation: String?
    public let binaryPath: String?

    public init(
        manager: PackageManagerKind,
        name: String,
        installedVersion: String?,
        installedVersions: [String] = [],
        latestVersion: String?,
        summary: String? = nil,
        category: String? = nil,
        homepage: String? = nil,
        docs: String? = nil,
        repo: String? = nil,
        lastUpdatedAt: String? = nil,
        pulseKind: String? = nil,
        installLocation: String? = nil,
        binaryPath: String? = nil
    ) {
        self.manager = manager
        self.name = name
        self.installedVersion = installedVersion
        self.installedVersions = Self.normalizedVersions(installedVersions, including: installedVersion)
        self.latestVersion = latestVersion
        self.summary = summary
        self.category = category
        self.homepage = homepage
        self.docs = docs
        self.repo = repo
        self.lastUpdatedAt = lastUpdatedAt
        self.pulseKind = pulseKind
        self.installLocation = installLocation
        self.binaryPath = binaryPath
    }

    public var isOutdated: Bool {
        guard let latestVersion, !latestVersion.isEmpty, !installedVersions.isEmpty else { return false }
        return !installedVersions.contains(latestVersion)
    }

    public var otherInstalledVersions: [String] {
        installedVersions.filter { $0 != installedVersion }
    }

    public func applying(metadata: PackageMetadata?) -> ManagedPackage {
        guard let metadata else { return self }
        return ManagedPackage(
            manager: manager,
            name: name,
            installedVersion: installedVersion,
            installedVersions: installedVersions,
            latestVersion: metadata.version ?? latestVersion,
            summary: metadata.summary ?? summary,
            category: metadata.category ?? category,
            homepage: metadata.homepage ?? homepage,
            docs: metadata.docs ?? docs,
            repo: metadata.repo ?? repo,
            lastUpdatedAt: metadata.lastUpdatedAt ?? lastUpdatedAt,
            pulseKind: metadata.pulseKind ?? pulseKind,
            installLocation: installLocation,
            binaryPath: binaryPath
        )
    }

    public static func consolidatingInstalledVersions(in packages: [ManagedPackage]) -> [ManagedPackage] {
        Dictionary(grouping: packages, by: { "\($0.manager.rawValue):\($0.name)" }).values.compactMap { group in
            guard let newest = group.max(by: { ($0.installedVersion ?? "").localizedStandardCompare($1.installedVersion ?? "") == .orderedAscending }) else { return nil }
            return ManagedPackage(
                manager: newest.manager,
                name: newest.name,
                installedVersion: newest.installedVersion,
                installedVersions: normalizedVersions(group.flatMap(\.installedVersions), including: newest.installedVersion),
                latestVersion: newest.latestVersion,
                summary: newest.summary,
                category: newest.category,
                homepage: newest.homepage,
                docs: newest.docs,
                repo: newest.repo,
                lastUpdatedAt: newest.lastUpdatedAt,
                pulseKind: newest.pulseKind,
                installLocation: newest.installLocation,
                binaryPath: newest.binaryPath
            )
        }
        .sorted {
            if $0.manager != $1.manager { return $0.manager.rawValue < $1.manager.rawValue }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    private static func normalizedVersions(_ versions: [String], including installedVersion: String?) -> [String] {
        Array(Set(versions + [installedVersion].compactMap { $0 }.filter { !$0.isEmpty }))
            .sorted { $0.localizedStandardCompare($1) == .orderedDescending }
    }
}

public struct PackageInventory: Codable, Equatable, Sendable {
    public let generatedAt: Date
    public let packages: [ManagedPackage]
    public let errors: [String]

    public init(generatedAt: Date = Date(), packages: [ManagedPackage], errors: [String] = []) {
        self.generatedAt = generatedAt
        self.packages = packages
        self.errors = errors
    }

    public var outdatedPackages: [ManagedPackage] {
        packages.filter(\.isOutdated)
    }

    public var categoryCounts: [String: Int] {
        Dictionary(grouping: packages.compactMap(\.category), by: { $0 })
            .mapValues(\.count)
    }

    public var managerCounts: [PackageManagerKind: Int] {
        Dictionary(grouping: packages, by: \.manager).mapValues(\.count)
    }
}

public struct PackageMetadata: Equatable, Sendable {
    public let summary: String?
    public let category: String?
    public let homepage: String?
    public let docs: String?
    public let repo: String?
    public let version: String?
    public let lastUpdatedAt: String?
    public let pulseKind: String?

    public init(summary: String?, category: String?, homepage: String?, docs: String? = nil, repo: String? = nil, version: String?, lastUpdatedAt: String? = nil, pulseKind: String? = nil) {
        self.summary = summary
        self.category = category
        self.homepage = homepage
        self.docs = docs
        self.repo = repo
        self.version = version
        self.lastUpdatedAt = lastUpdatedAt
        self.pulseKind = pulseKind
    }
}
