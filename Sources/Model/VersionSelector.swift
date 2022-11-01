//
//  Created by Marko Justinek on 19/8/21.
//  Copyright © 2021 Marko Justinek. All rights reserved.
//
//  Permission to use, copy, modify, and/or distribute this software for any
//  purpose with or without fee is hereby granted, provided that the above
//  copyright notice and this permission notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
//  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
//  SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
//  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
//  IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//

import Foundation

#if os(Linux)
import PactSwiftMockServerLinux
#elseif compiler(>=5.5)
@_implementationOnly import PactSwiftMockServer
#else
import PactSwiftMockServer
#endif

/// Provides a way to configure which pacts the provider verifies.
public struct VersionSelector: Codable, Equatable {

	// MARK: - Properties

	/// The name of the tag which applies to the pacticipant versions of the pacts to verify
	let tag: String?

	/// Whether or not to verify only the pact that belongs to the latest application version
	let latest: Bool

	/// A fallback tag if a pact for the specified `tag` does not exist
	let fallbackTag: String?

	/// Filter pacts by the specified consumer
	///
	/// When omitted, all consumers are included.
	let consumer: String?

	let mainBranch: Bool?
	let deployed: Bool?
	let released: Bool?
	let deployedOrReleased: Bool?
	let branch: String?
	let fallbackBranch: String?
	let matchingBranch: Bool?
	let environment: String?

	// MARK: - Initialization

	/// Defines a version configuration for which pacts the provider verifies
	///
	/// - Parameters:
	///   - tag: The version `tag` name of the consumer to verify
	///   - fallbackTag: The version `tag` to use if the initial `tag` does not exist
	///   - latest: Whether to verify only the pact belonging to the latest application version
	///   - consumer: Filter pacts by the specified consumer
	///
	/// See [https://docs.pact.io/selectors](https://docs.pact.io/selectors) for more context.
	///
	@available(*, deprecated)
	public init(tag: String = "", fallbackTag: String? = nil, latest: Bool = true, consumer: String? = nil) {
		self.tag = tag.isEmpty ? nil : tag
		self.fallbackTag = fallbackTag
		self.latest = latest
		self.consumer = consumer

		mainBranch = nil
		branch = nil
		fallbackBranch = nil
		matchingBranch = nil
		environment = nil
		deployed = nil
		released = nil
		deployedOrReleased = nil
	}

	/// The Consumer Version Selector configuring which pacts the provider verifies.
	///
	/// See [Consumer Version Selectors](https://docs.pact.io/pact_broker/advanced_topics/consumer_version_selectors) for more.
	///
	/// - warning: Note that this is a very unsafe initializer available for initializing this type.
	///
	/// To avoid unexpected behaviour **do read** through [Consumer Version Selectors](https://docs.pact.io/pact_broker/advanced_topics/consumer_version_selectors)
	/// document to learn how to set the values of Consumer Version Selectors effectively.
	///
	/// Example:
	/// ```
	///	let consumerInfo = ProviderVerifier.ConsumerInfo(
	///	  versionSelectors: [
	///	    VersionSelector(
	///	      tag: ProcessInfo.processInfo.environment["GIT_BRANCH"],
	///	      fallbackTag:"main"
	///	      latest: true
	///	    ),
	///	    VersionSelector(tag: "test", latest: true),
	///	    VersionSelector(tag: "production", latest: true
	///	  ]
	///	)
	///
	///	verifier.verifyPactsAt(
	///	  broker: broker,
	///	  providerInfo: providerInfo,
	///	  consumerInfo: consumerInfo,
	///	  includeWIPSince: includeWIPSince,
	///	  includePending: includePending
	///	)
	/// ```
	///
	public init(
		mainBranch: Bool? = nil,
		branch: String? = nil,
		fallbackBranch: String? = nil,
		matchingBranch: Bool? = nil,
		environment: String? = nil,
		latest: Bool = true,
		consumer: String? = nil,
		tag: String? = nil,
		fallbackTag: String? = nil,
		deployed: Bool? = nil,
		released: Bool? = nil,
		deployedOrReleased: Bool? = nil
	) {
		self.mainBranch = mainBranch
		self.branch = branch
		self.fallbackBranch = fallbackBranch
		self.matchingBranch = matchingBranch
		self.environment = environment
		self.latest = latest
		self.consumer = consumer
		self.tag = tag
		self.fallbackTag = fallbackTag
		self.deployed = deployed
		self.released = released
		self.deployedOrReleased = deployedOrReleased
	}

}

// MARK: - Internal

internal extension VersionSelector {

	/// Converts to JSON string
	///
	/// - Returns: A `String` representing `ProviderVerifier` in JSON format
	///
	func toJSONString() throws -> String {
		let jsonEncoder = JSONEncoder()
		let jsonData = try jsonEncoder.encode(self)
		guard let jsonString = String(data: jsonData, encoding: .utf8) else {
			throw ProviderVerifier.VerificationError.error("Invalid consumer version selector specified: \(self)")
		}

		return jsonString
	}

	var bridgedToMockServer: PactSwiftMockServer.VersionSelector {
		PactSwiftMockServer.VersionSelector(
			mainBranch: self.mainBranch,
			tag: self.tag,
			fallbackTag: self.fallbackTag,
			latest: self.latest,
			consumer: self.consumer,
			deployed: self.deployed,
			released: self.released,
			deployedOrReleased: self.deployedOrReleased,
			branch: self.branch,
			fallbackBranch: self.fallbackBranch,
			matchingBranch: self.matchingBranch,
			environment: self.environment
		)
	}

}
