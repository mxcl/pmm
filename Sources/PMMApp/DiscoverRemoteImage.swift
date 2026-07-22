import AppKit
import Foundation
import SwiftUI

struct DiscoverImagePayload: @unchecked Sendable {
    let data: Data
    let image: NSImage
}

struct DiscoverImageLoader: Sendable {
    typealias Fetch = @Sendable (URLRequest) async throws -> (Data, URLResponse)

    static let shared: Self = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: 16 * 1_024 * 1_024,
            diskCapacity: 128 * 1_024 * 1_024,
            directory: nil
        )
        let session = URLSession(configuration: configuration)
        return Self(fetch: { try await session.data(for: $0) })
    }()

    private let fetch: Fetch

    init(fetch: @escaping Fetch) {
        self.fetch = fetch
    }

    func load(
        _ url: URL,
        receive: @escaping @MainActor @Sendable (DiscoverImagePayload) -> Void
    ) async throws {
        var cachedData: Data?

        do {
            let cached = try await payload(for: request(url, cachePolicy: .returnCacheDataDontLoad))
            cachedData = cached.data
            await receive(cached)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            // A missing or invalid cache entry should not prevent the network load.
        }

        let refreshed = try await payload(for: request(url, cachePolicy: .reloadRevalidatingCacheData))
        guard refreshed.data != cachedData else { return }
        await receive(refreshed)
    }

    private func request(_ url: URL, cachePolicy: URLRequest.CachePolicy) -> URLRequest {
        URLRequest(url: url, cachePolicy: cachePolicy)
    }

    private func payload(for request: URLRequest) async throws -> DiscoverImagePayload {
        let (data, response) = try await fetch(request)
        guard let response = response as? HTTPURLResponse,
              200..<300 ~= response.statusCode
        else {
            throw URLError(.badServerResponse)
        }

        try Task.checkCancellation()
        return try await Task.detached(priority: .userInitiated) {
            guard let image = NSImage(data: data) else {
                throw URLError(.cannotDecodeContentData)
            }
            return DiscoverImagePayload(data: data, image: image)
        }.value
    }
}

enum DiscoverRemoteImagePhase {
    case empty
    case success(Image)
    case failure
}

struct DiscoverRemoteImage<Content: View>: View {
    let url: URL
    private let loader: DiscoverImageLoader
    private let content: (DiscoverRemoteImagePhase) -> Content

    @State private var image: NSImage?
    @State private var loadFailed = false

    init(
        url: URL,
        loader: DiscoverImageLoader = .shared,
        @ViewBuilder content: @escaping (DiscoverRemoteImagePhase) -> Content
    ) {
        self.url = url
        self.loader = loader
        self.content = content
    }

    var body: some View {
        content(phase)
            .task(id: url) {
                image = nil
                loadFailed = false

                do {
                    try await loader.load(url) { payload in
                        guard !Task.isCancelled else { return }
                        image = payload.image
                    }
                } catch is CancellationError {
                } catch {
                    if image == nil {
                        loadFailed = true
                    }
                }
            }
    }

    private var phase: DiscoverRemoteImagePhase {
        if let image {
            .success(Image(nsImage: image))
        } else if loadFailed {
            .failure
        } else {
            .empty
        }
    }
}
