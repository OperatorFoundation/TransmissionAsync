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
    var logger: Logger

    let straw: UnsafeStraw = UnsafeStraw()

    public init(_ channel: C, _ logger: Logger, verbose: Bool = false)
    {
        self.channel = channel
        self.logger = logger
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
        logger.debug("AsyncChannelConnection<\(self.channel)>.readSize(\(size)) - straw: \(self.straw.count)")

        if size == 0
        {
            logger.debug("AsyncChannelConnection<\(self.channel)>.readSize(\(size)) - size == 0")
            return Data()
        }

        if size <= self.straw.count
        {
            logger.debug("AsyncChannelConnection<\(self.channel)>.readSize(\(size)) - plenty of bytes in straw")
            let result = try self.straw.read(size: size)

            logger.debug("AsyncChannelConnection<\(self.channel)>.readSize(\(size)) - returning \(size) bytes, \(self.straw.count) left in straw")

            return result
        }

        logger.debug("AsyncChannelConnection<\(self.channel)>.readSize(\(size)) - not enough in straw, reading from socket")
        logger.debug("AsyncChannelConnection<\(self.channel)>.readSize(\(size)) - starting loop, while \(size) > \(self.straw.count)")
        
        while size > self.straw.count
        {
            logger.debug("AsyncChannelConnection<\(self.channel)>.readSize(\(size)) - in loop, reading from socket")
            let data = try await self.reader.read()

            logger.debug("AsyncChannelConnection<\(self.channel)>.readSize(\(size)) - in loop, adding \(data.count) bytes to \(self.straw.count) to get \(data.count + self.straw.count)/\(size)")

            self.straw.write(data)
        }

        logger.debug("AsyncChannelConnection<\(self.channel)>.readSize(\(size)) - excited loop with \(self.straw.count) bytes in buffer")

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
        logger.debug("AsyncChannelConnection<\(self.channel)>.readMinMaxSize(\(minSize), \(maxSize))")

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

        logger.debug("AsyncChannelConnection<\(self.channel)>.readMinMaxSize(\(minSize), \(maxSize)) - calling self.reader.read(\(minSize))")
        
        while self.straw.count < minSize
        {
            var someData = try await self.reader.read()
            
            if someData.count == 0
            {
                
                someData = try await self.reader.read(minSize)
            }
            
            self.straw.write(someData)
        }
        
        if self.straw.count < maxSize
        {
            let smoreData = try await self.reader.read()
            logger.debug("AsyncChannelConnection<\(self.channel)>.readMinMaxSize(): Second call to read() returned \(smoreData.count) bytes\n")
            self.straw.write(smoreData)
        }
        
        let dataSize = min(maxSize, self.straw.count)

        return try straw.read(maxSize: dataSize)
    }

    public func readWithLengthPrefix(prefixSizeInBits: Int) async throws -> Data
    {
        logger.debug("AsyncChannelConnection<\(self.channel)>.readWithLengthPrefix(\(prefixSizeInBits))")

        return try await self.reader.readWithLengthPrefix(prefixSizeInBits)
    }

    public func readWithLengthPrefixNonblocking(prefixSizeInBits: Int) async throws -> Data
    {
        logger.debug("AsyncChannelConnection<\(self.channel)>.readWithLengthPrefix(size: \(prefixSizeInBits))")

        return try await self.reader.readWithLengthPrefixNonblocking(prefixSizeInBits)
    }

    public func writeString(string: String) async throws
    {
        try await self.write(string.data)
    }

    public func write(_ data: Data) async throws
    {
        logger.debug("AsyncChannelConnection<\(self.channel)>.write(data: (\(data.count)) bytes)")
        try await self.writer.write(data)
    }

    public func writeWithLengthPrefix(_ data: Data, _ prefixSizeInBits: Int) async throws
    {
        logger.debug("AsyncChannelConnection<\(self.channel)>.writeWithLengthPrefix(data: (\(data.count)) bytes, size: \(prefixSizeInBits))")
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
