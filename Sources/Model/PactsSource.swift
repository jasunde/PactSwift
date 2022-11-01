//
//  Created by Marko Justinek on 31/10/2022.
//  Copyright © 2022 Marko Justinek. All rights reserved.
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

public enum PactsSource {

	/// Verify pacts on a Pact Broker
	@available(*, deprecated, message: "Use ProviderVerifier().verifyPactsAt(broker:) instead")
	case broker(PactBroker)

	/// Verify Pacts in a given directory (absolute path)
	case directory(String)

	/// Verify a specific Pact file (absolute path)
	case file(String)

	/// Verify specific pacts at URLs
	case url(URL, Either<SimpleAuth, APIToken>)

}
