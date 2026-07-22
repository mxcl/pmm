import Foundation
import Testing
@testable import PMMApp

@Test @MainActor func discoverImageLoaderPublishesCacheBeforeRevalidation() async throws {
    let cached = discoverTestPNG
    let refreshed = cached + Data([0])
    let stub = DiscoverImageFetchStub([
        .response(cached),
        .response(refreshed, delay: .milliseconds(100)),
    ])
    let loader = DiscoverImageLoader(fetch: { try await stub.fetch($0) })
    var received: [Data] = []

    try await loader.load(discoverTestURL) { received.append($0.data) }

    #expect(received == [cached, refreshed])
    #expect(await stub.cachePolicies == [.returnCacheDataDontLoad, .reloadRevalidatingCacheData])
}

@Test @MainActor func discoverImageLoaderDoesNotRepublishUnchangedData() async throws {
    let stub = DiscoverImageFetchStub([
        .response(discoverTestPNG),
        .response(discoverTestPNG),
    ])
    let loader = DiscoverImageLoader(fetch: { try await stub.fetch($0) })
    var received: [Data] = []

    try await loader.load(discoverTestURL) { received.append($0.data) }

    #expect(received == [discoverTestPNG])
}

@Test @MainActor func discoverImageLoaderKeepsCachedDataWhenRefreshFails() async {
    let stub = DiscoverImageFetchStub([
        .response(discoverTestPNG),
        .failure(URLError(.notConnectedToInternet)),
    ])
    let loader = DiscoverImageLoader(fetch: { try await stub.fetch($0) })
    var received: [Data] = []

    do {
        try await loader.load(discoverTestURL) { received.append($0.data) }
        Issue.record("Expected refresh to fail")
    } catch {
        #expect(received == [discoverTestPNG])
    }
}

@Test @MainActor func discoverImageLoaderFetchesNetworkAfterCacheMiss() async throws {
    let stub = DiscoverImageFetchStub([
        .failure(URLError(.resourceUnavailable)),
        .response(discoverTestPNG),
    ])
    let loader = DiscoverImageLoader(fetch: { try await stub.fetch($0) })
    var received: [Data] = []

    try await loader.load(discoverTestURL) { received.append($0.data) }

    #expect(received == [discoverTestPNG])
    #expect(await stub.cachePolicies == [.returnCacheDataDontLoad, .reloadRevalidatingCacheData])
}

private let discoverTestURL = URL(string: "https://example.com/image.png")!
private let discoverTestPNG = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=")!

private actor DiscoverImageFetchStub {
    enum Response: Sendable {
        case response(Data, delay: Duration = .zero)
        case failure(URLError)
    }

    private var responses: [Response]
    private(set) var cachePolicies: [URLRequest.CachePolicy] = []

    init(_ responses: [Response]) {
        self.responses = responses
    }

    func fetch(_ request: URLRequest) async throws -> (Data, URLResponse) {
        cachePolicies.append(request.cachePolicy)
        let response = responses.removeFirst()

        switch response {
        case .response(let data, let delay):
            try await Task.sleep(for: delay)
            return (
                data,
                HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: "HTTP/1.1",
                    headerFields: ["ETag": "\"fixture\""]
                )!
            )
        case .failure(let error):
            throw error
        }
    }
}
