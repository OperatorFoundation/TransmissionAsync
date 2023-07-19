//
//  AsyncStdioConnection.swift
//  
//
//  Created by Dr. Brandon Wiley on 7/18/23.
//

import Foundation
#if os(macOS) || os(iOS)
import os.log
#else
import Logging
#endif

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

    public func read(_ size: Int) async throws -> Data
    {
        return try await AsyncAwaitAsynchronizer.async
        {
            guard let data = try self.handle.read(upToCount: size) else
            {
                throw AsyncStdioConnectionError.readFailed
            }

            return data
        }
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
}
