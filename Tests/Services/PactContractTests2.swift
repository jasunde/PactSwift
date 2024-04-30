//
//  PactContractTests2.swift
//  
//
//  Created by Jason Sunde on 4/30/24.
//

import XCTest
@testable import PactSwift

final class PactContractTests2: XCTestCase {
  var pact: Pact!
  var builder: PactBuilder!
  var session: URLSession!
  
  override func setUpWithError() throws {
    try super.setUpWithError()
    
//    guard builder == nil else { return }
    
    do {
      try FileManager.default.removeItem(at: URL(fileURLWithPath: "/tmp/pacts/sanity-consumer-sanity-provider.json"))
    } catch {
      debugPrint("Could not remove file")
    }

    pact = try Pact(consumer: "sanity-consumer", provider: "sanity-provider")
      .withSpecification(.v4)
    
    let config = PactBuilder.Config(pactDirectory: "/tmp/pacts")
    builder = PactBuilder(pact: pact, config: config)
    session = URLSession(configuration: .ephemeral)
  }
  
  func test_object() async throws {
    try builder
      .uponReceiving("a request for an object")
      .given("some state")
      .withRequest(method: .GET, path: "/object")
      .willRespond(with: 200) { response in
        try response.jsonBody(
          .eachLike([
            "id": .integer(1),
            "name": .like("Test Object")
          ])
        )
      }
    
    try await builder.verify { context in
      let url = URL(string: "\(context.mockServerURL)/object")!
      _ = try await self.session.data(from: url)
    }
    
    try pact.writePactFile()
    
    let interactions = try getInteractions()
    
    XCTAssertEqual(1, interactions.count)
  }
  
  func test_object2() async throws {
    try builder
      .uponReceiving("a request for another object")
      .given("some state")
      .withRequest(method: .GET, path: "/object2")
      .willRespond(with: 200) { response in
        try response.jsonBody(
          .eachLike([
            "id": .integer(1),
            "name": .like("Test Object")
          ])
        )
      }
    
    try await builder.verify { context in
      let url = URL(string: "\(context.mockServerURL)/object2")!
      _ = try await self.session.data(from: url)
    }
    
    try pact.writePactFile()
    
    let interactions = try getInteractions()
    
    XCTAssertEqual(1, interactions.count)
  }
}


extension PactContractTests2 {
  func getJsonObject() throws -> [String: Any] {
    let fileContents = try String(contentsOfFile: "/tmp/pacts/sanity-consumer-sanity-provider.json")
    guard let data = fileContents.data(using: .utf8),
          let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
      return [:]
    }
    return jsonObject
  }
  
  func getInteractions(file: StaticString = #file, line: UInt = #line) throws -> [Any] {
    let jsonObject = try getJsonObject()
    return try XCTUnwrap(jsonObject["interactions"] as? [Any], file: file, line: line)
  }
}
