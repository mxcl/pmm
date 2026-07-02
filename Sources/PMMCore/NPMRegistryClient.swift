import Foundation

public struct NPMRegistryClient: Sendable {
    private let session: URLSession
    private let baseURL: URL

    public init(
        session: URLSession = .shared,
        baseURL: URL = URL(string: "https://registry.npmjs.org")!
    ) {
        self.session = session
        self.baseURL = baseURL
    }

    public func metadata(for name: String) async throws -> PackageMetadata? {
        var request = URLRequest(url: packageURL(for: name))
        request.setValue("PMM/1.0", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return try Self.metadata(from: data)
    }

    static func metadata(from data: Data) throws -> PackageMetadata? {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        let tags = json["dist-tags"] as? [String: Any]
        let latest = tags?["latest"] as? String
        let versions = json["versions"] as? [String: Any]
        let latestBody = latest.flatMap { versions?[$0] as? [String: Any] }
        let time = json["time"] as? [String: Any]

        return PackageMetadata(
            summary: json["description"] as? String ?? latestBody?["description"] as? String,
            category: "developer-tools",
            homepage: homepage(in: json) ?? latestBody?["homepage"] as? String,
            repo: repositoryURL(json["repository"] ?? latestBody?["repository"]),
            version: latest,
            lastUpdatedAt: latest.flatMap { time?[$0] as? String } ?? time?["modified"] as? String
        )
    }

    private func packageURL(for name: String) -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/")
        let encoded = name.addingPercentEncoding(withAllowedCharacters: allowed) ?? name
        components.percentEncodedPath = "/\(encoded)"
        return components.url!
    }

    private static func homepage(in json: [String: Any]) -> String? {
        json["homepage"] as? String
    }

    private static func repositoryURL(_ raw: Any?) -> String? {
        let value: String?
        if let raw = raw as? String {
            value = raw
        } else if let raw = raw as? [String: Any] {
            value = raw["url"] as? String
        } else {
            value = nil
        }
        return value?
            .replacingOccurrences(of: "git+", with: "")
            .replacingOccurrences(of: ".git", with: "")
    }
}
