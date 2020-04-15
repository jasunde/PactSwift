//
//  MockServer+Extension.swift
//  PactSwiftServices
//
//  Created by Marko Justinek on 14/4/20.
//  Copyright © 2020 Pact Foundation. All rights reserved.
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
import os.log

internal extension MockServer {

	func unusedPort() -> Int32 {
		var port = randomPort
		var (available, _) = tcpPortAvailable(port: port)
		while !available {
			port = randomPort
			(available, _) = tcpPortAvailable(port: port)
		}
		return Int32(port)
	}

}

private extension MockServer {

	var randomPort: in_port_t {
		return in_port_t(arc4random_uniform(2000) + 4000)
	}

	func log(_ message: String, file: String = #file, function: String = #function) {
		os_log("%@ (%@): %@", log: .default, type: .debug, file, function, message)
	}

	//
	// The following code block referenced from: https://stackoverflow.com/a/49728137
	//
	func tcpPortAvailable(port: in_port_t) -> (Bool, descr: String) {
		let socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0)
		guard socketFileDescriptor != -1 else {
			return (false, "SocketCreationFailed: \(descriptionOfLastError())")
		}

		var addr = sockaddr_in()
		let sizeOfSockkAddr = MemoryLayout<sockaddr_in>.size
		addr.sin_len = __uint8_t(sizeOfSockkAddr)
		addr.sin_family = sa_family_t(AF_INET)
		addr.sin_port = Int(OSHostByteOrder()) == OSLittleEndian ? _OSSwapInt16(port) : port
		addr.sin_addr = in_addr(s_addr: inet_addr("0.0.0.0"))
		addr.sin_zero = (0, 0, 0, 0, 0, 0, 0, 0)
		var bindAddress = sockaddr()
		memcpy(&bindAddress, &addr, Int(sizeOfSockkAddr))

		if Darwin.bind(socketFileDescriptor, &bindAddress, socklen_t(sizeOfSockkAddr)) == -1 {
			let details = descriptionOfLastError()
			release(socket: socketFileDescriptor)
			return (false, "\(port), BindFailed, \(details)")
		}

		if listen(socketFileDescriptor, SOMAXCONN ) == -1 {
			let details = descriptionOfLastError()
			release(socket: socketFileDescriptor)
			return (false, "\(port), ListenFailed, \(details)")
		}

		release(socket: socketFileDescriptor)
		return (true, "\(port) is free for use")
	}

	func release(socket: Int32) {
		Darwin.shutdown(socket, SHUT_RDWR)
		close(socket)
	}

	func descriptionOfLastError() -> String {
		return String.init(cString: (UnsafePointer(strerror(errno))))
	}

}
