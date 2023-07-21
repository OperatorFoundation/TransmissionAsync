//
//  Reader.swift
//  
//
//  Created by Dr. Brandon Wiley on 7/5/23.
//

import Foundation
import Logging

public actor Reader<T: Readable>
{
    let reader: T
    let logger: Logger

    public init(_ reader: T, _ logger: Logger)
    {
        self.reader = reader
        self.logger = logger
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
        let firstData = try await self.reader.read(size)
        let nextSize = try await handler(firstData)
        let nextData = try await self.reader.read(nextSize)
        return nextData
    }
}
