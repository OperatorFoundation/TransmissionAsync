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
        try await self.reader.read()
    }

    // Reads exactly size bytes
    public func readSize(_ size: Int) async throws -> Data
    {
        if size == 0
        {
            return Data()
        }

        return try await self.reader.read(size)
    }

    // reads up to maxSize bytes
    public func readMaxSize(_ maxSize: Int) async throws -> Data
    {
        if maxSize == 0
        {
            return Data()
        }

        let straw: Straw = Straw()
        while straw.count < maxSize
        {
            do
            {
                let data = try await self.reader.read(1)
                straw.write(data)
            }
            catch
            {
                return try straw.read()
            }
        }

        return try straw.read()
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

    public func readWithLengthPrefix(prefixSizeInBits: Int, timeoutMilliseconds: Int) async throws -> Data
    {
        if self.verbose
        {
            self.logger.debug("AsyncChannelConnection.readWithLengthPrefix(size: \(prefixSizeInBits), timeoutMilliseconds: \(timeoutMilliseconds))")
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
}
