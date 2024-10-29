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

    let stdin = FileHandleReadable(FileHandle.standardInput)
    let stdout = FileHandleWritable(FileHandle.standardOutput)

    public init()
    {
    }

    public func close() throws
    {
        try self.stdout.handle.close()
    }
}

public enum AsyncStdioConnectionError: Error
{
    case readFailed
    case unimplemented
}
