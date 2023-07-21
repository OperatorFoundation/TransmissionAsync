//
//  AsyncStdioConnection.swift
//
//
//  Created by Dr. Brandon Wiley on 7/21/23.
//

import Foundation
import Logging

import Chord
import Socket
import Straw

public class AsyncSystemdConnection: AsyncChannelConnection<SystemdChannel>
{
    public init(_ logger: Logger)
    {
        let channel = SystemdChannel()

        super.init(channel, logger)
    }
}

public class SystemdChannel: Channel
{
    public typealias R = FileHandleReadable
    public typealias W = FileHandleWritable

    public var readable: FileHandleReadable
    {
        return self.stdin
    }

    public var writable: FileHandleWritable
    {
        return self.stdout
    }

    let stdin = FileHandleReadable(3)
    let stdout = FileHandleWritable(3)

    public init()
    {
    }

    public func close() throws
    {
        try self.stdout.handle.close()
    }
}

public class FileHandleReadable: Readable
{
    public let handle: FileHandle

    let straw: Straw = Straw()

    public init(_ fd: Int32)
    {
        self.handle = FileHandle(fileDescriptor: fd)
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
}

public class FileHandleWritable: Writable
{
    public let handle: FileHandle

    public init(_ fd: Int32)
    {
        self.handle = FileHandle(fileDescriptor: fd)
    }

    public func write(_ data: Data) async throws
    {
        await AsyncAwaitAsynchronizer.async
        {
            self.handle.write(data)
        }
    }
}

public enum AsyncSystemdConnectionError: Error
{
    case readFailed
}
