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
        return try await self.reader.read(size)
    }

    public func read(_ size: Int, handler: (Data) async throws -> Int) async throws -> Data
    {
        if verbose
        {
            self.logger.trace("Reader.read(\(size), handler)")
        }

        let firstData = try await self.reader.read(size)

        if verbose
        {
            self.logger.trace("Reader.read - firstData: \(firstData.hex)")
        }

        let nextSize = try await handler(firstData)

        if verbose
        {
            self.logger.trace("Reader.read - nextSize: \(nextSize)")
        }

        let nextData = try await self.reader.read(nextSize)

        if verbose
        {
            self.logger.trace("Reader.read - nextData: \(nextData.hex)")
        }

        return nextData
    }
}
