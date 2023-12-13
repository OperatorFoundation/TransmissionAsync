//
//  AsyncTcpListener.swift
//  
//
//  Created by Dr. Brandon Wiley on 7/5/23.
//

import Foundation
import Logging

import Chord
import Socket

public class AsyncTcpSocketListener: AsyncListener
{
    public typealias C = SocketChannel

    let listener: Socket
    let logger: Logger
    let verbose: Bool

    public init(host: String? = nil, port: Int, _ logger: Logger, verbose: Bool = false) throws
    {
        let listener = try Socket.create()
        try listener.listen(on: port, allowPortReuse: false)

        self.listener = listener
        self.logger = logger
        self.verbose = verbose
    }

    public func accept() async throws -> AsyncConnection
    {
        return try await AsyncAwaitAsynchronizer.async
        {
            let socket = try self.listener.acceptClientConnection(invokeDelegate: false)
            return AsyncTcpSocketConnection(socket, self.logger, verbose: self.verbose)
        }
    }

    public func close() async throws
    {
        self.listener.close()
    }
}
