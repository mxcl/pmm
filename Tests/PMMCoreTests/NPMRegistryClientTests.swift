import Foundation
import Testing
@testable import PMMCore

@Test func npmRegistryClientMapsPackageMetadata() throws {
    let data = Data("""
    {
      "description": "TypeScript is a language for application scale JavaScript development",
      "dist-tags": { "latest": "5.9.2" },
      "repository": { "url": "git+https://github.com/microsoft/TypeScript.git" },
      "time": {
        "modified": "2026-06-30T00:00:00.000Z",
        "5.9.2": "2026-06-20T00:00:00.000Z"
      },
      "versions": {
        "5.9.2": { "homepage": "https://www.typescriptlang.org/" }
      }
    }
    """.utf8)

    #expect(try NPMRegistryClient.metadata(from: data) == PackageMetadata(
        summary: "TypeScript is a language for application scale JavaScript development",
        category: "developer-tools",
        homepage: "https://github.com/microsoft/TypeScript",
        version: "5.9.2",
        lastUpdatedAt: "2026-06-20T00:00:00.000Z"
    ))
}
