//
//  Created by Marko Justinek on 1/11/2022.
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

#if os(Linux)
import PactSwiftMockServerLinux
#elseif compiler(>=5.5)
@_implementationOnly import PactSwiftMockServer
#else
import PactSwiftMockServer
#endif

public extension ProviderVerifier {

	struct ConsumerInfo {
		/// Consumer Version Selectors defining which versions to verify
		let versionSelectors: [PactSwiftMockServer.VersionSelector]

		/// Consumer tags to verify (deprecated)
		let tags: [String]

		public init(versionSelectors: [VersionSelector], tags: [String] = []) {
			self.versionSelectors = versionSelectors.map { $0.bridgedToMockServer }
			self.tags = tags
		}
	}

}
