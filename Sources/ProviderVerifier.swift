//
//  Created by Marko Justinek on 20/8/21.
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
import XCTest

#if os(Linux)
import PactSwiftMockServerLinux
#elseif compiler(>=5.5)
@_implementationOnly import PactSwiftMockServer
#else
import PactSwiftMockServer
#endif

/// Entry point for provider verification
public final class ProviderVerifier {

	let verifier: VerifierInterface
	private let errorReporter: ErrorReportable

	/// Initializes a `Verifier` object for provider verification
	@available(*, deprecated, message: "Use init?(name:version) instead.")
	public convenience init() {
		self.init(verifier: Verifier(), errorReporter: ErrorReporter())
	}

	public convenience init?(name: String, version: String) {
		guard let verifier = Verifier(name: name, version: version) else { return nil }

		self.init(verifier: verifier, errorReporter: ErrorReporter())
	}

	/// Initializes a `Verifier` object
	///
	/// - Parameters:
	///   - verifier: The verifier object handling provider verification
	///   - errorReporter: Error reporting or intercepting object
	///
	/// This initializer is marked `internal` for testing purposes!
	///
	internal init(verifier: VerifierInterface, errorReporter: ErrorReportable? = nil) {
		self.verifier = verifier
		self.errorReporter = errorReporter ?? ErrorReporter()
	}

	/// Executes provider verification test
	///
	/// - Parameters:
	///   - options: Flags and args to use when verifying a provider
	///   - file: The file in which to report the error in
	///   - line: The line on which to report the error on
	///   - completionBlock: Completion block executed at the end of verification
	///
	/// - Returns: A `Result<Bool, VerificationError>` where error describes the failure
	///
	@discardableResult
	@available(*, deprecated, message: "Use .verify() in combination with other operands setting the verification options.")
	public func verify(options: Options, file: FileString? = #file, line: UInt? = #line, completionBlock: (() -> Void)? = nil) -> Result<Bool, ProviderVerifier.VerificationError> {
		switch verifier.verifyProvider(options: options.args) {
		case .success(let value):
			completionBlock?()
			return .success(value)
		case .failure(let error):
			failWith(error.description, file: file, line: line)
			completionBlock?()
			return .failure(VerificationError.error(error.description))
		}
	}

	// MARK: - Using handle to MockServer verifier

	/// Sets the provider details for the Pact verifier
	///
	/// Passing `nil` for any URL field (eg: not providing port) will be replaced by the default value for that field.
	@discardableResult
	public func setProviderInfo(name: String, url: URL) -> ProviderVerifier {
		verifier.setProviderInfo(name: name, url: url)
		return self
	}

	/// Sets the filters for the Pact verifier
	///
	/// - Parameters:
	///   - description: A regular expression value
	///   - state:
	///   - noState:
	@discardableResult
	public func setFilter(description: String?, state: String? = nil, noState: Bool = false) -> ProviderVerifier {
		verifier.setFilter(description: description, state: state, noState: noState)
		return self
	}

	/// Sets the provider state for the Pact verifier
	@discardableResult
	public func setProviderState(url: URL, teardown: Bool = false, body: Bool = false) -> ProviderVerifier {
		verifier.setProviderState(url: url, teardown: teardown, body: body)
		return self
	}

	/// Sets options used by the verifier when calling the provider
	@discardableResult
	public func setVerificationOptions(disableSSL: Bool, timeout: UInt) -> ProviderVerifier {
		verifier.setVerificationOptions(disableSSL: disableSSL, timeout: timeout)
		return self
	}

	/// Verifies Pacts at given source
	@discardableResult
	public func verifyPactsAt(source: PactsSource) -> ProviderVerifier {
		switch source {
		case let .directory(directory):
			verifier.verifyPactsInDirectory(directory)

		case let .file(file):
			verifier.verifyPactFile(file)

		case let .url(url, auth):
			switch auth {
			case let .auth(auth):
				verifier.verifyPactAtURL(url: url, authentication: .auth(PactSwiftMockServer.SimpleAuth(username: auth.username, password: auth.password)))
			case let .token(token):
				verifier.verifyPactAtURL(url: url, authentication: .token(Token(token.token)))
			}

		case let .broker(broker):
		switch broker.authentication {
		case let .auth(auth):
			verifier.verifyPactsAtPactBroker(urlString: broker.url, authentication: .auth(PactSwiftMockServer.SimpleAuth(username: auth.username, password: auth.password) ))
		case let .token(apiToken):
			verifier.verifyPactsAtPactBroker(urlString: broker.url, authentication: .token(Token(apiToken.token)))
			}
		}

		return self
	}

	/// Sets the Pact broker as a source to verify.
	///
	/// Fetches all the Pact files form the broker that match the provider name and the consumer version selectors
	/// See [Consumer Version Selectors](https://docs.pact.io/pact_broker/advanced_topics/consumer_version_selectors/) for more context
	///
	/// - Parameters:
	///   - broker: The Pact broker as source of Pacts to verify
	///   - providerOptions: Options of the provider to verify
	///   - consumerInfo: Options for the consumer(s) to verify
	///   - includeWIPSince: Include WIP Pacts since provided date
	///   - includePending: Include Pact(s) that are set as pending
	///
	/// Use `setProviderInfo(name: url:)` to define which provider you want to verify.
	///
	@discardableResult
	public func verifyPactsAt(
		broker: Broker,
		providerOptions: ProviderOptions,
		consumerInfo: ConsumerInfo,
		includeWIPSince: Date? = nil,
		includePending: Bool = false
	) -> ProviderVerifier {
		do {
			try verifier.verifyPactsAtPactBroker(
				url: broker.url,
				authentication: mapAuthentication(broker.authentication),
				providerTags: providerOptions.tags,
				providerBranch: providerOptions.branch,
				versionSelectors: consumerInfo.versionSelectors,
				consumerTags: consumerInfo.tags,
				enablePending: includePending,
				includeWIPPactsSince: includeWIPSince
			)
		} catch {
			failWith("Failed to set Pact broker. Error: \(error)")
		}

		return self
	}

	/// Sets custom headers sent to provider
	///
	/// - Parameter headers: A dictionary of key value pairs
	///
	/// - Returns: Instance of `self`
	///
	/// - Warning: Key and value must contain ASCII characters (32-127) only!
	///
	@discardableResult
	public func setCustomHeaders(_ headers: [String: String]) -> ProviderVerifier {
		verifier.setCustomHeaders(headers)
		return self
	}

	/// Sets the options used when publishing verification results to the Pact broker
	///
	/// - Parameters:
	///   - providerVersion: Version of the provider to publish
	///   - providerBranch: Name of the branch used for verification
	///   - buildURL: URL to the build which ran the verification
	///   - providerTags: Collection of tags for the provider
	///
	@discardableResult
	public func setPublishOptions(providerVersion: String, providerBranch: String, buildURL: URL, providerTags: [String]) -> ProviderVerifier {
		verifier.setPublishOptions(providerVersion: providerVersion, providerBranch: providerBranch, buildURL: buildURL, providerTags: providerTags)
		return self
	}

	/// Executes provider verification test
	///
	/// - Parameters:
	///   - file: The file in which to report the error in
	///   - line: The line on which to report the error on
	///   - completion: Completion block executed at the end of verification
	///
	/// - Returns: A `Result<Bool, VerificationError>` where error describes the failure
	///
	public func verify(file: FileString? = #file, line: UInt? = #line, completion: (() -> Void)? = nil) -> Result<Bool, ProviderVerifier.VerificationError> {
		switch verifier.verify() {
		case let .success(result):
			completion?()
			return .success(result)
		case let .failure(error):
			failWith(error.description, file: file, line: line)
			completion?()
			return .failure(VerificationError.error(error.description))
		}
	}

}

// MARK: - Private

private extension ProviderVerifier {

	/// Fail the test and raise the failure in `file` at `line`
	func failWith(_ message: String, file: FileString? = nil, line: UInt? = nil) {
		if let file = file, let line = line {
			errorReporter.reportFailure(message, file: file, line: line)
		} else {
			errorReporter.reportFailure(message)
		}
	}

	func mapAuthentication(_ auth: Either<SimpleAuth, APIToken>) -> PactSwiftMockServer.Either<PactSwiftMockServer.SimpleAuth, Token> {
		switch auth {
		case let .auth(auth):
			return .auth(PactSwiftMockServer.SimpleAuth(username: auth.username, password: auth.password))
		case let .token(apiToken):
			return .token(Token(apiToken.token))
		}
	}

}
