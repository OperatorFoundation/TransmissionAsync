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

        try await AsyncAwaitAsynchronizer.async
        {
            try socket.connect(to: host, port: Int32(port))
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
        self.logger.info("SocketChannel.close was called explicitly")
        self.socket.close()
    }
}

public class SocketReadable: Readable
{
    let socket: Socket
    let logger: Logger
    let straw: Straw = Straw()

    public init(_ socket: Socket, logger: Logger)
    {
        self.socket = socket
        self.logger = logger
    }

    public func read() async throws -> Data
    {
        self.logger.trace("SocketReadable.read()")
        print("SocketReadable.read()")
        return try await AsyncAwaitAsynchronizer.async
        {
            var data: Data = Data()

            print("actual socket will be read... \(self.socket)")
            try self.socket.read(into: &data)
            print("actual socket was read. \(self.socket)")

            return data
        }
    }

    public func read(_ size: Int) async throws -> Data
    {
        self.logger.trace("SocketReadable.read(size:\(size))")
        print("SocketReadable.read(size: \(size))")

        if size == 0
        {
            return Data()
        }

        self.logger.trace("entering async")
        return try await AsyncAwaitAsynchronizer.async
        {
            self.logger.trace("entered async")

            self.logger.trace("starting loop \(self.straw.count) \(size)")
            while self.straw.count < size
            {
                self.logger.trace("inside loop \(self.straw.count) \(size)")

                var data: Data = Data()

                print("actual socket will be read... \(self.socket)")
                try self.socket.read(into: &data)
                print("actual socket was read. \(self.socket)")

                self.straw.write(data)

                self.logger.trace("end of loop \(self.straw.count) \(size)")
            }

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
