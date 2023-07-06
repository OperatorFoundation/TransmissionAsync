//
//  AsyncTcpListener.swift
//  
//
//  Created by Dr. Brandon Wiley on 7/5/23.
//

import Foundation
#if os(macOS) || os(iOS)
import os.log
#else
import Logging
#endif

import Socket

public class AsyncTcpSocketListener: AsyncListener
{
    public typealias C = SocketChannel

    let listener: Socket
    let logger: Logger

    public init(host: String? = nil, port: Int, _ logger: Logger) throws
    {
        let listener = try Socket.create()
        try listener.listen(on: port, allowPortReuse: false)

        self.listener = listener
        self.logger = logger
    }

    public func accept() async throws -> AsyncConnection
    {
        let socket = try self.listener.acceptClientConnection(invokeDelegate: false)
        return AsyncTcpSocketConnection(socket, self.logger)
    }
}
