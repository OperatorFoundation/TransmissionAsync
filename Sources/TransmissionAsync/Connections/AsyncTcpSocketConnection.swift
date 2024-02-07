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
        let channel = SocketChannel(socket, logger: logger, verbose: verbose)

        super.init(channel, logger, verbose: verbose)
    }
}

public class SocketChannel: Channel
{
    public typealias R = SocketReadable
    public typealias W = SocketWritable

    public var readable: SocketReadable
    {
        return SocketReadable(self.socket, logger: self.logger, verbose: self.verbose)
    }

    public var writable: SocketWritable
    {
        return SocketWritable(self.socket, logger: self.logger, verbose: self.verbose)
    }

    let socket: Socket
    let logger: Logger
    let verbose: Bool

    public init(_ socket: Socket, logger: Logger, verbose: Bool = false)
    {
        self.socket = socket
        self.logger = logger
        self.verbose = verbose
    }

    public func close()
    {
        if self.verbose
        {
            self.logger.info("SocketChannel.close() was called explicitly")
        }

        self.socket.close()
    }
}

public class SocketReadable: Readable
{
    let socket: Socket
    let logger: Logger
    let verbose: Bool
    let straw: UnsafeStraw

    public init(_ socket: Socket, logger: Logger, verbose: Bool = false)
    {
        self.socket = socket
        self.logger = logger
        self.verbose = verbose

        self.straw = UnsafeStraw()
    }

    public func read() async throws -> Data
    {
        if self.straw.count > 0
        {
            return try self.straw.read()
        }

        if self.verbose
        {
            self.logger.debug("SocketReadable.read()")
        }

        return try await AsyncAwaitAsynchronizer.async
        {
            var data: Data = Data()

            if self.verbose
            {
                self.logger.debug("SocketReadable.read() - reading from socket")
            }

            try self.socket.read(into: &data)

            if self.verbose
            {
                self.logger.debug("SocketReadable.read() - reading from socket \(data.count) bytes")
            }

            if data.isEmpty, self.socket.remoteConnectionClosed
            {
                throw AsyncTcpSocketConnectionError.remoteConnectionClosed
            }

            return data
        }
    }

    public func read(_ size: Int) async throws -> Data
    {
        if self.verbose
        {
            self.logger.debug("SocketReadable.read(\(size))")
        }

        try self.socket.setBlocking(mode: true)

        if size == 0
        {
            return Data()
        }

        if self.verbose
        {
            self.logger.debug("SocketReadable.read(\(size)) - starting Asynchronizer")
        }

        let result = try await AsyncAwaitAsynchronizer.async
        {
            if self.verbose
            {
                self.logger.debug("SocketReadable.read(\(size)) - entered Asynchronizer")
            }

            while self.straw.count < size
            {
                var data: Data = Data()

                if self.verbose
                {
                    self.logger.debug("SocketReadable.read(\(size)) - calling self.socket.read")
                }

                if self.verbose
                {
                    self.logger.debug("SocketReadable.read(\(size)) - reading from socket")
                }

                try self.socket.read(into: &data)

                if self.verbose
                {
                    self.logger.debug("SocketReadable.read(\(size)) - read from socket \(data.count) bytes")
                }

                if data.isEmpty, self.socket.remoteConnectionClosed
                {
                    if self.verbose
                    {
                        self.logger.debug("SocketReadable.read(\(size)) - error reading from socket")
                    }

                    throw AsyncTcpSocketConnectionError.remoteConnectionClosed
                }

                self.straw.write(data)
            }

            try self.socket.setBlocking(mode: false)

            return try self.straw.read(size: size)
        }

        if self.verbose
        {
            self.logger.debug("SocketReadable.read(\(size)) - left Asynchronizer")
        }

        if self.verbose
        {
            self.logger.debug("SocketReadable.read(\(size)) - returning \(result.count) bytes")
        }

        return result
    }

    public func readNonblocking(_ size: Int) async throws -> Data
    {
        if size == 0
        {
            return Data()
        }

        return try await AsyncAwaitAsynchronizer.async
        {
            var firstRead: Bool = true
            while self.straw.count < size
            {
                var data: Data = Data()

                try self.socket.read(into: &data)

                if firstRead, data.isEmpty
                {
                    // In non-blocking mode, we can throw because there was no data.
                    throw AsyncTcpSocketConnectionError.noData
                }
                else
                {
                    // Once we have read at least 1 byte, we can no longer do non-blocking mode.
                    // This is because if we return early, the data will be lost.
                    // We can't just return a short Data because that violates the contract of read(size:).
                    firstRead = false
                    try self.socket.setBlocking(mode: true)
                }

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
    let logger: Logger
    let verbose: Bool

    public init(_ socket: Socket, logger: Logger, verbose: Bool = false)
    {
        self.socket = socket
        self.logger = logger
        self.verbose = verbose
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

public enum AsyncTcpSocketConnectionError: Error
{
    case unimplemented
    case noData
    case remoteConnectionClosed
}
