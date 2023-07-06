//
//  AsyncTcpListener.swift
//  
//
//  Created by Dr. Brandon Wiley on 7/5/23.
//

import Foundation

import Socket

public class AsyncTcpSocketListener: AsyncListener
{
    public typealias C = SocketChannel

    let listener: Socket

    public init(host: String? = nil, port: Int) throws
    {
        let listener = try Socket.create()
        try listener.listen(on: port, allowPortReuse: false)

        self.listener = listener
    }

    public func accept() async throws -> AsyncConnection<SocketChannel>
    {
        let socket = try self.listener.acceptClientConnection(invokeDelegate: false)
        return AsyncTcpSocketConnection(socket)
    }
}
