//
//  AsyncChannelConnection.swift
//  
//
//  Created by Dr. Brandon Wiley on 7/6/23.
//

import Foundation
import Logging

import Datable
import Straw
import SwiftHexTools

open class AsyncChannelConnection<C: Channel>: AsyncConnection
{
    let channel: C
    let reader: Reader<C.R>
    let writer: Writer<C.W>
    let logger: Logger
    let verbose: Bool

    let straw: UnsafeStraw = UnsafeStraw()

    public init(_ channel: C, _ logger: Logger, verbose: Bool = false)
    {
        self.channel = channel
        self.logger = logger
        self.verbose = verbose

        self.reader = Reader(channel.readable, logger, verbose: verbose)
        self.writer = Writer(channel.writable, logger)
    }

    // Reads an amount of data decided by magic
    public func read() async throws -> Data
    {
        if self.straw.isEmpty
        {
            return try await self.reader.read()
        }
        else
        {
            return try self.straw.read()
        }
    }

    // Reads exactly size bytes
    public func readSize(_ size: Int) async throws -> Data
    {
        print("AsyncChannelConnection.readSize")
        print("AsyncChannelConnection.readSize(\(size)) - straw: \(self.straw.count)")

        if size == 0
        {
            print("AsyncChannelConnection.readSize(\(size)) - size == 0")
            return Data()
        }

        if size <= self.straw.count
        {
            print("AsyncChannelConnection.readSize(\(size)) - plenty of bytes in straw")
            let result = try self.straw.read(size: size)

            print("AsyncChannelConnection.readSize(\(size)) - returning \(size) bytes, \(self.straw.count) left in straw")

            return result
        }

        print("AsyncChannelConnection.readSize(\(size)) - not enough in straw, reading from socket")

        print("AsyncChannelConnection.readSize(\(size)) - starting loop, while \(size) > \(self.straw.count)")
        while size > self.straw.count
        {
            print("AsyncChannelConnection.readSize(\(size)) - in loop, reading from socket")
            let data = try await self.reader.read()

            print("AsyncChannelConnection.readSize(\(size)) - in loop, adding \(data.count) bytes to \(self.straw.count) to get \(data.count + self.straw.count)/\(size)")

            self.straw.write(data)
        }

        print("AsyncChannelConnection.readSize(\(size)) - excited loop with \(self.straw.count) bytes in buffer")

        return try self.straw.read(size: size)
    }

    /// Reads up to maxSize bytes
    public func readMaxSize(_ maxSize: Int) async throws -> Data
    {
        if maxSize == 0
        {
            return Data()
        }

        // Fill the buffer
        while straw.count < maxSize
        {
            // Read new data from the network
            // It's important not to catch this try as that's how we signal the caller that the connection has been closed.
            let data = try await self.reader.read()

            // If we get zero bytes back
            // We may have timed out
            // Return whatever we have in the straw
            guard data.count > 0 else
            {
                if straw.count > 0
                {
                    return try straw.read(maxSize: maxSize)
                }
                else
                {
                    return Data()
                }
            }

            straw.write(data)

            await Task.yield()
        }

        // We've filled the buffer up to maxSize, so we can return now.
        return try straw.read(maxSize: maxSize)
    }

    // reads at least minSize bytes and up to maxSize bytes
    public func readMinMaxSize(_ minSize: Int, _ maxSize: Int) async throws -> Data
    {
        if self.verbose
        {
            self.logger.debug("AsyncChannelConnection.readMinMaxSize(\(minSize), \(maxSize))")
        }

        guard maxSize >= minSize else
        {
            throw AsyncChannelConnectionError.badArguments
        }

        guard minSize > 0 else
        {
            throw AsyncChannelConnectionError.badArguments
        }

        if maxSize == 0
        {
            return Data()
        }

        if verbose
        {
            self.logger.debug("AsyncChannelConnection.readMinMaxSize(\(minSize), \(maxSize)) - calling self.reader.read(\(minSize))")
        }

        let minData = try await self.reader.read(minSize)
        self.straw.write(minData)

        if verbose
        {
            self.logger.debug("AsyncChannelConnection.readMinMaxSize(\(minSize), \(maxSize)) - read minimum data \(minData.count) / \(minSize)")
        }

        let dataSize = min(maxSize, self.straw.count)

        return try straw.read(maxSize: dataSize)
    }

    public func readWithLengthPrefix(prefixSizeInBits: Int) async throws -> Data
    {
        if self.verbose
        {
            self.logger.debug("AsyncChannelConnection.readWithLengthPrefix(\(prefixSizeInBits))")
        }

        if self.verbose
        {
            self.logger.debug("AsyncChannelConnection.readWithLengthPrefix - reading length bytes")
        }

        return try await self.reader.readWithLengthPrefix(prefixSizeInBits)
    }

    public func readWithLengthPrefixNonblocking(prefixSizeInBits: Int) async throws -> Data
    {
        if self.verbose
        {
            self.logger.debug("AsyncChannelConnection.readWithLengthPrefix(size: \(prefixSizeInBits))")
        }

        return try await self.reader.readWithLengthPrefixNonblocking(prefixSizeInBits)
    }

    public func writeString(string: String) async throws
    {
        try await self.write(string.data)
    }

    public func write(_ data: Data) async throws
    {
        try await self.writer.write(data)
    }

    public func writeWithLengthPrefix(_ data: Data, _ prefixSizeInBits: Int) async throws
    {
        try await self.writer.writeWithLengthPrefix(data, prefixSizeInBits)
    }

    public func close() async throws
    {
        try await self.channel.close()
    }
}

public enum AsyncChannelConnectionError: Error
{
    case badPrefixSize(Int)
    case badLengthPrefix
    case unimplemented
    case badArguments
}
