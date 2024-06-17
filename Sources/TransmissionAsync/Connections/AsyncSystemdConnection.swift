//
//  AsyncSystemdConnection.swift
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
    public init(_ logger: Logger, verbose: Bool = false)
    {
        let channel = SystemdChannel()

        super.init(channel, logger, verbose: verbose)
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

public enum AsyncSystemdConnectionError: Error
{
    case readFailed
    case noData
}
