import Foundation
import Testing
@testable import PMMCore

@Test func cratesIOClientMapsCrateMetadata() throws {
    let data = Data("""
    {
      "crate": {
        "description": "Search recursively",
        "homepage": "https://burntsushi.net/ripgrep/",
        "documentation": "https://docs.rs/ripgrep",
        "repository": "https://github.com/BurntSushi/ripgrep",
        "max_version": "14.1.1",
        "updated_at": "2026-06-30T12:00:00Z"
      }
    }
    """.utf8)

    #expect(try CratesIOClient.metadata(from: data) == PackageMetadata(
        summary: "Search recursively",
        category: "developer-tools",
        homepage: "https://burntsushi.net/ripgrep/",
        docs: "https://docs.rs/ripgrep",
        repo: "https://github.com/BurntSushi/ripgrep",
        version: "14.1.1",
        lastUpdatedAt: "2026-06-30T12:00:00Z"
    ))
}
