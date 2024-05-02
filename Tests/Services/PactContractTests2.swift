//
//  PactContractTests2.swift
//
//
//  Created by Jason Sunde on 4/30/24.
//

import XCTest
@testable import PactSwift

final class PactContractTests2: XCTestCase {
  static var builder: PactBuilder!
  
  static let consumerName = "sanity-consumer"
  static let providerName = "sanity-provider"
  static let pactDirectory = "/tmp/pacts"
  
  static var pactFilePath: String {
    "\(Self.pactDirectory)/\(Self.consumerName)-\(Self.providerName).json"
  }
  
  override class func setUp() {
    PactContractTests2.removeFile(Self.pactFilePath)
    
    let pact = try! Pact(consumer: Self.consumerName, provider: Self.providerName)
      .withSpecification(.v4)
    
    let config = PactBuilder.Config(pactDirectory: Self.pactDirectory)
    Self.builder = PactBuilder(pact: pact, config: config)
  }
  
  override class func tearDown() {
    do {
      let pactJson = try getJsonObject(pactFilePath)
      let interactions = try getInteractions(pactJson)
      
      try validateBugExampleResponse(interactions)
      try validateAnimalsWithChildrenResponse(interactions)
    } catch {
      assert(false, "Test failure during teardown")
    }
  }
  
  private static let bugExampleDescription = "bug example"
  func testBugExample() async throws {
    try Self.builder
      .uponReceiving(Self.bugExampleDescription)
      .given("some state")
      .withRequest(method: .GET, path: "/bugfix")
      .willRespond(with: 200) { response in
        try response.jsonBody(
          .like([
            "array_of_objects": .eachLike(
              [
                "key_string": .like("String value"),
                "key_int": .integer(123),
                "key_for_matcher_array": .eachLike("matcher_array_value", min: 0),
                "key_for_datetime_expression": .datetime("today +1 day", format: "yyyy-MM-dd")
              ]
            ),
            "array_of_strings": .eachLike("A string", min: 0),
            "includes_like": .includes("included")
          ])
        )
      }
    try await Self.builder.verify { context in
      let url = try context.buildRequestURL(path: "/bugfix")
      let request = URLRequest(url: url)
      _ = try await URLSession(configuration: .ephemeral).data(for: request)
    }
  }
  
  private static func validateBugExampleResponse(_ interactions: [Any]) throws {
    let interaction = try Self.extract(
      .matchingRules,
      in: .response,
      interactions: interactions,
      description: Self.bugExampleDescription
    )
    let expectedMatchers = [
      "$.array_of_objects",
      "$.array_of_objects[*].key_int",
      "$.array_of_objects[*].key_string",
      "$.array_of_objects[*].key_for_matcher_array",
      "$.array_of_strings",
      "$.includes_like",
    ]
    assertExistence(of: expectedMatchers, in: interaction)
  }
  
  private static var animalsWithChildrenDescription = "a request for animals with children"
  func testExample_AnimalsWithChildren() async throws {
    try Self.builder
      .uponReceiving(Self.animalsWithChildrenDescription)
      .given("animals have children")
      .withRequest(method: .GET, path: "/animals")
      .willRespond(with: 200) { response in
        try response.jsonBody(
          .like([
            "animals": .eachLike(
              [
                "children": .eachLike("Mary", min: 0),
              ]
            )
          ])
        )
      }
    try await Self.builder.verify { context in
      let url = try context.buildRequestURL(path: "/animals")
      let request = URLRequest(url: url)
      _ = try await URLSession(configuration: .ephemeral).data(for: request)
    }
  }
  
  private static func validateAnimalsWithChildrenResponse(_ interactions: [Any]) throws {
    let interaction = try Self.extract(
      .matchingRules,
      in: .response,
      interactions: interactions,
      description: Self.animalsWithChildrenDescription
    )
    let expectedMatchers = [
      "$.animals",
      "$.animals[*].children",
    ]
    assertExistence(of: expectedMatchers, in: interaction)
  }
  
  private static func assertExistence(
    of matchers: [String],
    in interaction: [String: Any],
    file: StaticString = #file,
    line: UInt = #line) {
      let found = matchers.filter { expectedKey -> Bool in
        interaction.contains { key, _ -> Bool in
          expectedKey == key
        }
      }
      let missing = matchers.filter { !found.contains($0) }
      assert(
        found.count == matchers.count,
        "Not all expected generators found in Pact contract file. Missing: \(missing)",
        file: file,
        line: line
      )
    }
  
}




private extension PactContractTests2 {
  static func getJsonObject(_ filename: String) throws -> [String: Any] {
    let fileContents = try String(contentsOfFile: filename)
    guard let data = fileContents.data(using: .utf8),
          let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
      return [:]
    }
    return jsonObject
  }
  
  static func getInteractions(_ pactJson: [String: Any], file: StaticString = #file, line: UInt = #line) throws -> [Any] {
    return try XCTUnwrap(pactJson["interactions"] as? [Any], file: file, line: line)
  }
  
  enum PactNode: String {
    case matchingRules
    case generators
  }
  
  enum Direction: String {
    case request
    case response
  }
  
  func fail(function: String, request: String? = nil, response: String? = nil, error: Error? = nil) {
    XCTFail(
    """
    Expected network request to succeed in \(function)!
    Request URL: \t\(String(describing: request))
    Response:\t\(String(describing: response))
    Reason: \t\(String(describing: error?.localizedDescription))
    """
    )
  }
  
  static func extract(
    _ type: PactNode,
    in direction: Direction,
    interactions: [Any],
    description: String) throws -> [String: Any] {
      let interaction = try XCTUnwrap(
        interactions.first { interaction -> Bool in
          (interaction as! [String: Any])["description"] as! String == description
        } as? [String: Any],
        "Interaction not found with description: \(description)"
      )
      let direction = try XCTUnwrap(interaction[direction.rawValue] as? [String: Any])
      let type = try XCTUnwrap(direction[type.rawValue] as? [String: Any])
      return try XCTUnwrap(type["body"] as? [String: Any])
    }
  
  static func fileExists(_ filename: String) -> Bool {
    FileManager.default.fileExists(atPath: filename)
  }
  
  static func removeFile(_ filename: String) {
    guard fileExists(filename) else { return }
    do {
      try FileManager.default.removeItem(at: URL(fileURLWithPath: filename))
    } catch {
      debugPrint("Could not remove file \(filename)")
    }
  }
  
}
