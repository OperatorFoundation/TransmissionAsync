//
//  Reader.swift
//  
//
//  Created by Dr. Brandon Wiley on 7/5/23.
//

import Foundation
import Logging

import SwiftHexTools

public actor Reader<T: Readable>
{
    let reader: T
    let logger: Logger
    let verbose: Bool

    public init(_ reader: T, _ logger: Logger, verbose: Bool = false)
    {
        self.reader = reader
        self.logger = logger
        self.verbose = verbose
    }

    public func read() async throws -> Data
    {
        return try await self.reader.read()
    }

    public func read(_ size: Int) async throws -> Data
    {
        if size == 0
        {
            return Data()
        }

        return try await self.reader.read(size)
    }

    public func readWithLengthPrefix(_ prefixSizeInBits: Int) async throws -> Data
    {
        if verbose
        {
            self.logger.trace("Reader.readWithLengthPrefix(\(prefixSizeInBits))")
        }

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
                throw ReaderError.badPrefixSize(prefixSizeInBits)
        }

        let lengthBytes = try await self.reader.read(sizeInBytes)

        if self.verbose
        {
            self.logger.debug("Reader.readWithLengthPrefix - \(lengthBytes.count) \(lengthBytes.hex) \(prefixSizeInBits)")
        }

        let length: Int
        switch prefixSizeInBits
        {
            case 8:
                guard let tempLength = lengthBytes.uint8 else
                {
                    throw ReaderError.badLengthPrefix
                }

                length = Int(tempLength)

            case 16:
                guard let tempLength = lengthBytes.maybeNetworkUint16 else
                {
                    throw ReaderError.badLengthPrefix
                }

                length = Int(tempLength)

            case 32:
                guard let tempLength = lengthBytes.maybeNetworkUint32 else
                {
                    if self.verbose
                    {
                        self.logger.error("bad length prefix for 32 bits \(lengthBytes.count) \(lengthBytes.hex)")
                    }

                    throw ReaderError.badLengthPrefix
                }

                length = Int(tempLength)

            case 64:
                guard let tempLength = lengthBytes.maybeNetworkUint64 else
                {
                    throw ReaderError.badLengthPrefix
                }

                length = Int(tempLength)

            default:
                throw ReaderError.badPrefixSize(prefixSizeInBits)
        }

        if verbose
        {
            self.logger.trace("Reader.read - length: \(length)")
        }

        let nextData: Data
        if length > 0
        {
            nextData = try await self.reader.read(length)
        }
        else
        {
            nextData = Data()
        }

        if verbose
        {
            self.logger.trace("Reader.read - nextData: \(nextData.hex)")
        }

        return nextData
    }
}

public enum ReaderError: Error
{
    case badPrefixSize(Int)
    case badLengthPrefix
}
