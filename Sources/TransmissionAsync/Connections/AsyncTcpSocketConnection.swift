//
//  AsyncTcpClientNetworkConnection.swift
//  TransmissionAsync
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
import Straw

public class AsyncTcpSocketConnection: AsyncChannelConnection<SocketChannel>
{
    public convenience init(_ host: String, _ port: Int, _ logger: Logger) async throws
    {
        let socket = try Socket.create()

        try await withCheckedThrowingContinuation
        {
            continuation in

            do
            {
                try socket.connect(to: host, port: Int32(port))
                continuation.resume(returning: ())
            }
            catch
            {
                continuation.resume(throwing: error)
            }
        }

        self.init(socket, logger)
    }

    public init(_ socket: Socket, _ logger: Logger)
    {
        let channel = SocketChannel(socket)

        super.init(channel, logger)
    }
}

public class SocketChannel: Channel
{
    public typealias R = SocketReadable
    public typealias W = SocketWritable

    public var readable: SocketReadable
    {
        return SocketReadable(self.socket)
    }

    public var writable: SocketWritable
    {
        return SocketWritable(self.socket)
    }

    let socket: Socket

    public init(_ socket: Socket)
    {
        self.socket = socket
    }

    public func close()
    {
        self.socket.close()
    }
}

public class SocketReadable: Readable
{
    let socket: Socket
    let straw: Straw = Straw()

    public init(_ socket: Socket)
    {
        self.socket = socket
    }

    public func read(_ size: Int) async throws -> Data
    {
        return try await withCheckedThrowingContinuation
        {
            continuation in

            var data: Data = Data()

            do
            {
                while data.count < size
                {
                        try self.socket.read(into: &data)
                }

                straw.write(data)

                let result = try straw.read(size: size)
                continuation.resume(returning: result)
            }
            catch
            {
                continuation.resume(throwing: error)
            }
        }
    }
}

public class SocketWritable: Writable
{
    let socket: Socket

    public init(_ socket: Socket)
    {
        self.socket = socket
    }

    public func write(_ data: Data) async throws
    {
        try await withCheckedThrowingContinuation
        {
            continuation in

            var dataToWrite = data

            do
            {
                while dataToWrite.count > 0
                {
                    let wrote = try self.socket.write(from: dataToWrite)
                    dataToWrite = data.dropFirst(wrote)
                }

                continuation.resume(returning: ())
            }
            catch
            {
                continuation.resume(throwing: error)
            }
        }
    }
}
