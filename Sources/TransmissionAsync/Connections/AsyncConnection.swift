//
//  AsyncConnection.swift
//  
//
//  Created by Dr. Brandon Wiley on 7/5/23.
//

import Foundation
#if os(macOS) || os(iOS)
import os.log
#else
import Logging
#endif

import Datable
import Straw

open class AsyncConnection<C: Channel>
{
    let channel: C
    let reader: Reader<C.R>
    let writer: Writer<C.W>
    let logger: Logger

    public init(_ channel: C, _ logger: Logger)
    {
        self.channel = channel
        self.logger = logger
        self.reader = Reader(channel.readable, logger)
        self.writer = Writer(channel.writable, logger)
    }

    // Reads exactly size bytes
    public func readSize(_ size: Int) async throws -> Data
    {
        try await self.reader.read(size)
    }

    // reads up to maxSize bytes
    public func readMaxSize(_ maxSize: Int) async throws -> Data
    {
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
        let sizeInBytes: Int

        switch prefixSizeInBits
        {
            case 8:
                sizeInBytes = 1

            case 16:
                sizeInBytes = 2

            case 32:
                sizeInBytes = 4

            case 64:
                sizeInBytes = 8

            default:
                throw AsyncConnectionError.badPrefixSize(prefixSizeInBits)
        }

        return try await self.reader.read(sizeInBytes)
        {
            lengthBytes in

            let length: Int
            switch sizeInBytes
            {
                case 8:
                    guard let tempLength = lengthBytes.uint8 else
                    {
                        throw AsyncConnectionError.badLengthPrefix
                    }

                    length = Int(tempLength)

                case 16:
                    guard let tempLength = lengthBytes.maybeNetworkUint16 else
                    {
                        throw AsyncConnectionError.badLengthPrefix
                    }

                    length = Int(tempLength)

                case 32:
                    guard let tempLength = lengthBytes.maybeNetworkUint32 else
                    {
                        throw AsyncConnectionError.badLengthPrefix
                    }

                    length = Int(tempLength)

                case 64:
                    guard let tempLength = lengthBytes.maybeNetworkUint64 else
                    {
                        throw AsyncConnectionError.badLengthPrefix
                    }

                    length = Int(tempLength)

                default:
                    throw AsyncConnectionError.badPrefixSize(prefixSizeInBits)
            }

            return length
        }
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
        let length: Int = data.count

        let lengthBytes: Data
        switch prefixSizeInBits
        {
            case 8:
                let length8 = UInt8(length)
                guard let lengthData = length8.maybeNetworkData else
                {
                    throw AsyncConnectionError.badLengthPrefix
                }

                lengthBytes = lengthData
            case 16:
                let length16 = UInt16(length)
                guard let lengthData = length16.maybeNetworkData else
                {
                    throw AsyncConnectionError.badLengthPrefix
                }

                lengthBytes = lengthData
            case 32:
                let length32 = UInt32(length)
                guard let lengthData = length32.maybeNetworkData else
                {
                    throw AsyncConnectionError.badLengthPrefix
                }

                lengthBytes = lengthData
            case 64:
                let length64 = UInt64(length)
                guard let lengthData = length64.maybeNetworkData else
                {
                    throw AsyncConnectionError.badLengthPrefix
                }

                lengthBytes = lengthData

            default:
                throw AsyncConnectionError.badLengthPrefix
        }

        try await self.writer.write([lengthBytes, data])
    }

    public func close() async throws
    {
        self.channel.close()
    }
}

public enum AsyncConnectionError: Error
{
    case badPrefixSize(Int)
    case badLengthPrefix
}
