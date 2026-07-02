import Foundation

public struct CratesIOClient: Sendable {
    private let session: URLSession
    private let baseURL: URL

    public init(
        session: URLSession = .shared,
        baseURL: URL = URL(string: "https://crates.io/api/v1")!
    ) {
        self.session = session
        self.baseURL = baseURL
    }

    public func metadata(for name: String) async throws -> PackageMetadata? {
        var request = URLRequest(url: baseURL.appending(path: "crates").appending(path: name))
        request.setValue("PMM/1.0", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return try Self.metadata(from: data)
    }

    static func metadata(from data: Data) throws -> PackageMetadata? {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let crate = json["crate"] as? [String: Any] else { return nil }
        return PackageMetadata(
            summary: crate["description"] as? String,
            category: "developer-tools",
            homepage: crate["homepage"] as? String ?? crate["repository"] as? String ?? crate["documentation"] as? String,
            version: crate["max_version"] as? String,
            lastUpdatedAt: crate["updated_at"] as? String
        )
    }
}
