//
//  Created by Oliver Jones on 9/1/2023.
//  Copyright © 2023 Oliver Jones. All rights reserved.
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

import XCTest

@testable import PactSwift

class MatcherContentTypeTests: MatcherTestCase {

	/* TODO: Disabled for the moment. Until I understand its use case.
	func testMatcher_MatchContentType() throws {
		let json = try jsonString(for: .contentType("image/jpeg"))
		
		XCTAssertEqual(
			json,
			#"""
			{
			  "pact:matcher:type" : "contentType",
			  "value" : "image/jpeg"
			}
			"""#
		)
	}
	*/
}