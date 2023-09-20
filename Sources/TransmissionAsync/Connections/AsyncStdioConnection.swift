//
//  AsyncStdioConnection.swift
//  
//
//  Created by Dr. Brandon Wiley on 7/18/23.
//

import Foundation
import Logging

import Chord
import Socket
import Straw

public class AsyncStdioConnection: AsyncChannelConnection<StdioChannel>
{
    public init(_ logger: Logger)
    {
        let channel = StdioChannel()

        super.init(channel, logger)
    }
}

public class StdioChannel: Channel
{
    public typealias R = StdinReadable
    public typealias W = StdoutWritable

    public var readable: StdinReadable
    {
        return self.stdin
    }

    public var writable: StdoutWritable
    {
        return self.stdout
    }

    let stdin = StdinReadable()
    let stdout = StdoutWritable()

    public init()
    {
    }

    public func close() throws
    {
        try self.stdout.handle.close()
    }
}

public class StdinReadable: Readable
{
    public let handle = FileHandle.standardInput

    let straw: Straw = Straw()

    public init()
    {
    }

    public func read() async throws -> Data
    {
        return await AsyncAwaitAsynchronizer.async
        {
            return self.handle.availableData
        }
    }

    public func read(_ size: Int) async throws -> Data
    {
        if size == 0
        {
            return Data()
        }

        return try await AsyncAwaitAsynchronizer.async
        {
            while self.straw.count < size
            {
                guard let data = try self.handle.read(upToCount: size) else
                {
                    throw AsyncStdioConnectionError.readFailed
                }

                self.straw.write(data)
            }

            let result = try self.straw.read(size: size)
            return result
        }
    }

    public func readNonblocking(_ size: Int) async throws -> Data
    {
        throw AsyncStdioConnectionError.unimplemented
    }
}

public class StdoutWritable: Writable
{
    public let handle = FileHandle.standardOutput

    public init()
    {
    }

    public func write(_ data: Data) async throws
    {
        await AsyncAwaitAsynchronizer.async
        {
            self.handle.write(data)
        }
    }
}

public enum AsyncStdioConnectionError: Error
{
    case readFailed
    case unimplemented
}
