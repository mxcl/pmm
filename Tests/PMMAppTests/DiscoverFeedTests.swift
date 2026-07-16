import Foundation
import Testing
@testable import PMMApp

@Test func discoverFeedGroupsEditorialNewPackagesAndRecommendations() throws {
    let feed = try JSONDecoder().decode(DiscoverFeed.self, from: Data("""
    {"content":[
      {"id":"editorial:one","type":"editorial","title":"Featured","primaryPackageID":"npm:typescript"},
      {"id":"new","type":"newPackages","packageIDs":["brew:faker"]},
      {"id":"for-you","type":"personalizedRecommendations","candidatePackageIDs":["npm:typescript"]}
    ],"packages":{
      "brew:faker":{"id":"brew:faker","displayName":"Faker","agentSummary":"Fake data","homepage":"https://faker.readthedocs.io/"},
      "npm:typescript":{"id":"npm:typescript","displayName":"TypeScript","agentSummary":"Static checking","homepage":"https://www.typescriptlang.org/"}
    }}
    """.utf8))

    #expect(feed.editorial?.title == "Featured")
    #expect(feed.newPackages.map(\.displayName) == ["Faker"])
    #expect(feed.recommendations.map(\.displayName) == ["TypeScript"])
}
