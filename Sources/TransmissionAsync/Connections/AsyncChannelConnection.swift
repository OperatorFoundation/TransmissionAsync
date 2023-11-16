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
            print("AsyncChannelConnection.readSize(\(size)) - \(size) <= \(self.straw.count)")
            return try self.straw.read(size: size)
        }
        else
        {
            print("AsyncChannelConnection.readSize(\(size)) - \(size) > \(self.straw.count)")
            let bytesNeeded = size - self.straw.count
            print("AsyncChannelConnection.readSize(\(size)) - \(bytesNeeded) bytes needed")

            print("AsyncChannelConnection.readSize(\(size)) - calling self.reader.read(\(bytesNeeded))")
            let data = try await self.reader.read(bytesNeeded)
            self.straw.write(data)
            return try self.straw.read(size: size)
        }
    }

    /// Reads up to maxSize bytes
    public func readMaxSize(_ maxSize: Int) async throws -> Data
    {
        if maxSize == 0
        {
            return Data()
        }

        while straw.count < maxSize
        {
            do
            {
                let data = try await self.reader.read()
                
                // If we get zero bytes back
                // We may have timed out
                // Return whatever we have in the straw
                guard data.count > 0 else
                {
                    return try straw.read(maxSize: maxSize)
                }
                
                straw.write(data)
            }
            catch
            {
                return try straw.read(maxSize: maxSize)
            }

            await Task.yield()
        }

        return try straw.read(maxSize: maxSize)
    }

    // reads at least minSize bytes and up to maxSize bytes
    public func readMinMaxSize(_ minSize: Int, _ maxSize: Int) async throws -> Data
    {
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

        let minData = try await self.reader.read(minSize)
        self.straw.write(minData)

        while straw.count < maxSize
        {
            do
            {
                let data = try await self.reader.read()

                // If we get zero bytes back
                // We may have timed out
                // Return whatever we have in the straw
                guard data.count > 0 else
                {
                    return try straw.read(maxSize: maxSize)
                }

                straw.write(data)
            }
            catch
            {
                return try straw.read(maxSize: maxSize)
            }

            await Task.yield()
        }

        return try straw.read(maxSize: maxSize)
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
