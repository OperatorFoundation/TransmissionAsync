//
//  AsyncTcpSocketConnection.swift
//  TransmissionAsync
//
//  Created by Dr. Brandon Wiley on 7/5/23.
//

import Foundation
import Logging

import Chord
import Socket
import Straw

public class AsyncTcpSocketConnection: AsyncChannelConnection<SocketChannel>
{
    public convenience init(_ host: String, _ port: Int, _ logger: Logger, verbose: Bool = false) async throws
    {
        let socket = try Socket.create()
        try socket.setBlocking(mode: false)
        try socket.setReadTimeout(value: 1 * 1000) // 1 second in milliseconds
        try socket.setWriteTimeout(value: 1 * 1000) // 1 seconds in milliseconds

        try await AsyncAwaitAsynchronizer.async
        {
            try socket.connect(to: host, port: Int32(port), timeout: 30 * 1000) // 30 seconds in milliseconds
        }

        self.init(socket, logger, verbose: verbose)
    }

    public init(_ socket: Socket, _ logger: Logger, verbose: Bool = false)
    {
        let channel = SocketChannel(socket, logger: logger)

        super.init(channel, logger, verbose: verbose)
    }
}

public class SocketChannel: Channel
{
    public typealias R = SocketReadable
    public typealias W = SocketWritable

    public var readable: SocketReadable
    {
        return SocketReadable(self.socket, logger: self.logger)
    }

    public var writable: SocketWritable
    {
        return SocketWritable(self.socket)
    }

    let socket: Socket
    let logger: Logger

    public init(_ socket: Socket, logger: Logger)
    {
        self.socket = socket
        self.logger = logger
    }

    public func close()
    {
        self.logger.info("SocketChannel.close() was called explicitly")
        self.socket.close()
    }
}

public class SocketReadable: Readable
{
    let socket: Socket
    let logger: Logger
    let straw: UnsafeStraw

    public init(_ socket: Socket, logger: Logger)
    {
        self.socket = socket
        self.logger = logger
        self.straw = UnsafeStraw()
    }

    public func read() async throws -> Data
    {
        return try await AsyncAwaitAsynchronizer.async
        {
            var data: Data = Data()

            try self.socket.read(into: &data)

            return data
        }
    }

    public func read(_ size: Int) async throws -> Data
    {
        try self.socket.setBlocking(mode: true)

        if size == 0
        {
            return Data()
        }

        return try await AsyncAwaitAsynchronizer.async
        {
            while self.straw.count < size
            {
                var data: Data = Data()

                try self.socket.read(into: &data)

                self.straw.write(data)
            }

            try self.socket.setBlocking(mode: false)

            return try self.straw.read(size: size)
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
        try await AsyncAwaitAsynchronizer.async
        {
            var dataToWrite = data

            while dataToWrite.count > 0
            {
                let wrote = try self.socket.write(from: dataToWrite)
                dataToWrite = data.dropFirst(wrote)
            }
        }
    }
}
